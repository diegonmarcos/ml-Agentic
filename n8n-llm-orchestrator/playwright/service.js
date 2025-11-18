/**
 * Playwright Browser Automation Service
 * Version: 4.0.0
 *
 * HTTP service for Web Agent browser automation
 * Exposes endpoints for navigation, extraction, interaction
 *
 * Usage:
 *   npm install
 *   npm start
 *
 * Endpoints:
 *   POST /navigate      - Navigate to URL and capture screenshot
 *   POST /extract       - Extract content from current page
 *   POST /click         - Click element by selector
 *   POST /fill          - Fill form field
 *   POST /screenshot    - Take screenshot of current page
 *   POST /close         - Close browser session
 *   GET  /health        - Health check
 */

const express = require('express');
const {chromium} = require('playwright');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const SCREENSHOT_DIR = process.env.SCREENSHOT_DIR || './screenshots';
const DEFAULT_TIMEOUT = parseInt(process.env.DEFAULT_TIMEOUT) || 30000;

// Middleware
app.use(express.json());

// Browser session management
const sessions = new Map();

// Ensure screenshot directory exists
fs.mkdir(SCREENSHOT_DIR, {recursive: true}).catch(console.error);

// Utility: Generate session ID
function generateSessionId() {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// Utility: Get or create browser session
async function getSession(sessionId, options = {}) {
    if (sessionId && sessions.has(sessionId)) {
        return sessions.get(sessionId);
    }

    // Launch new browser
    const browser = await chromium.launch({
        headless: options.headless !== false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const context = await browser.newContext({
        viewport: {width: 1920, height: 1080},
        userAgent: options.userAgent || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        ...(options.cookies && {storageState: {cookies: options.cookies}})
    });

    const page = await context.newPage();
    page.setDefaultTimeout(DEFAULT_TIMEOUT);

    const newSessionId = sessionId || generateSessionId();
    const session = {browser, context, page, id: newSessionId};
    sessions.set(newSessionId, session);

    return session;
}

// Utility: Close session
async function closeSession(sessionId) {
    if (!sessions.has(sessionId)) {
        return false;
    }

    const session = sessions.get(sessionId);
    await session.browser.close();
    sessions.delete(sessionId);
    return true;
}

// Utility: Save screenshot
async function saveScreenshot(page, sessionId) {
    const filename = `${sessionId}_${Date.now()}.png`;
    const filepath = path.join(SCREENSHOT_DIR, filename);
    await page.screenshot({path: filepath, fullPage: false});
    return filepath;
}

/**
 * POST /navigate
 * Navigate to URL and capture screenshot
 *
 * Body:
 * {
 *   "url": "https://example.com",
 *   "sessionId": "optional_session_id",
 *   "waitFor": "networkidle|load|domcontentloaded",
 *   "screenshot": true,
 *   "headless": true
 * }
 *
 * Response:
 * {
 *   "success": true,
 *   "sessionId": "session_xxx",
 *   "url": "https://example.com",
 *   "title": "Page Title",
 *   "screenshot": "/path/to/screenshot.png",
 *   "html": "<html>...",
 *   "duration_ms": 2100
 * }
 */
app.post('/navigate', async (req, res) => {
    const start = Date.now();
    let session;

    try {
        const {url, sessionId, waitFor = 'networkidle', screenshot = true, headless = true} = req.body;

        if (!url) {
            return res.status(400).json({
                success: false,
                error: 'URL is required'
            });
        }

        // Get or create session
        session = await getSession(sessionId, {headless});
        const {page} = session;

        // Navigate
        await page.goto(url, {waitUntil: waitFor, timeout: DEFAULT_TIMEOUT});

        // Get page info
        const title = await page.title();
        const html = await page.content();

        // Screenshot
        let screenshotPath = null;
        if (screenshot) {
            screenshotPath = await saveScreenshot(page, session.id);
        }

        const duration = Date.now() - start;

        res.json({
            success: true,
            sessionId: session.id,
            url: page.url(),
            title,
            screenshot: screenshotPath,
            html,
            duration_ms: duration
        });

    } catch (error) {
        console.error('Navigate error:', error);

        // Save error screenshot if session exists
        let errorScreenshot = null;
        if (session && session.page) {
            try {
                errorScreenshot = await saveScreenshot(session.page, session.id);
            } catch (e) {
                console.error('Error screenshot failed:', e);
            }
        }

        res.status(500).json({
            success: false,
            error: error.message,
            screenshot: errorScreenshot,
            duration_ms: Date.now() - start
        });
    }
});

/**
 * POST /extract
 * Extract content from page
 *
 * Body:
 * {
 *   "sessionId": "session_xxx",
 *   "selector": "optional_css_selector",
 *   "extractType": "text|html|markdown|structured"
 * }
 *
 * Response:
 * {
 *   "success": true,
 *   "content": "extracted content",
 *   "contentType": "text",
 *   "duration_ms": 150
 * }
 */
app.post('/extract', async (req, res) => {
    const start = Date.now();

    try {
        const {sessionId, selector, extractType = 'text'} = req.body;

        if (!sessionId || !sessions.has(sessionId)) {
            return res.status(400).json({
                success: false,
                error: 'Valid sessionId is required'
            });
        }

        const {page} = sessions.get(sessionId);
        let content;

        if (selector) {
            const element = await page.locator(selector);
            if (extractType === 'html') {
                content = await element.innerHTML();
            } else {
                content = await element.textContent();
            }
        } else {
            if (extractType === 'html') {
                content = await page.content();
            } else if (extractType === 'markdown') {
                // Basic HTML to Markdown conversion
                const html = await page.content();
                content = htmlToMarkdown(html);
            } else if (extractType === 'structured') {
                // Extract structured data (headings, lists, tables)
                content = await page.evaluate(() => {
                    const result = {
                        title: document.title,
                        headings: [],
                        paragraphs: [],
                        lists: [],
                        tables: []
                    };

                    document.querySelectorAll('h1, h2, h3').forEach(h => {
                        result.headings.push({
                            level: h.tagName,
                            text: h.textContent.trim()
                        });
                    });

                    document.querySelectorAll('p').forEach(p => {
                        result.paragraphs.push(p.textContent.trim());
                    });

                    document.querySelectorAll('ul, ol').forEach(list => {
                        const items = Array.from(list.querySelectorAll('li')).map(li => li.textContent.trim());
                        result.lists.push({type: list.tagName, items});
                    });

                    document.querySelectorAll('table').forEach(table => {
                        const rows = Array.from(table.querySelectorAll('tr')).map(tr => {
                            return Array.from(tr.querySelectorAll('th, td')).map(cell => cell.textContent.trim());
                        });
                        result.tables.push(rows);
                    });

                    return result;
                });
            } else {
                content = await page.textContent('body');
            }
        }

        res.json({
            success: true,
            content,
            contentType: extractType,
            duration_ms: Date.now() - start
        });

    } catch (error) {
        console.error('Extract error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            duration_ms: Date.now() - start
        });
    }
});

/**
 * POST /click
 * Click element by selector
 */
app.post('/click', async (req, res) => {
    const start = Date.now();

    try {
        const {sessionId, selector} = req.body;

        if (!sessionId || !sessions.has(sessionId)) {
            return res.status(400).json({
                success: false,
                error: 'Valid sessionId is required'
            });
        }

        if (!selector) {
            return res.status(400).json({
                success: false,
                error: 'Selector is required'
            });
        }

        const {page} = sessions.get(sessionId);
        await page.click(selector);

        // Wait for navigation if triggered
        await page.waitForLoadState('networkidle', {timeout: 5000}).catch(() => {});

        res.json({
            success: true,
            duration_ms: Date.now() - start
        });

    } catch (error) {
        console.error('Click error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            duration_ms: Date.now() - start
        });
    }
});

/**
 * POST /fill
 * Fill form field
 */
app.post('/fill', async (req, res) => {
    const start = Date.now();

    try {
        const {sessionId, selector, value} = req.body;

        if (!sessionId || !sessions.has(sessionId)) {
            return res.status(400).json({
                success: false,
                error: 'Valid sessionId is required'
            });
        }

        if (!selector || value === undefined) {
            return res.status(400).json({
                success: false,
                error: 'Selector and value are required'
            });
        }

        const {page} = sessions.get(sessionId);
        await page.fill(selector, value.toString());

        res.json({
            success: true,
            duration_ms: Date.now() - start
        });

    } catch (error) {
        console.error('Fill error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            duration_ms: Date.now() - start
        });
    }
});

/**
 * POST /screenshot
 * Take screenshot of current page
 */
app.post('/screenshot', async (req, res) => {
    const start = Date.now();

    try {
        const {sessionId, fullPage = false} = req.body;

        if (!sessionId || !sessions.has(sessionId)) {
            return res.status(400).json({
                success: false,
                error: 'Valid sessionId is required'
            });
        }

        const session = sessions.get(sessionId);
        const {page} = session;

        const filepath = await saveScreenshot(page, session.id);

        res.json({
            success: true,
            screenshot: filepath,
            duration_ms: Date.now() - start
        });

    } catch (error) {
        console.error('Screenshot error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            duration_ms: Date.now() - start
        });
    }
});

/**
 * POST /close
 * Close browser session
 */
app.post('/close', async (req, res) => {
    const start = Date.now();

    try {
        const {sessionId} = req.body;

        if (!sessionId) {
            return res.status(400).json({
                success: false,
                error: 'sessionId is required'
            });
        }

        const closed = await closeSession(sessionId);

        if (!closed) {
            return res.status(404).json({
                success: false,
                error: 'Session not found'
            });
        }

        res.json({
            success: true,
            message: 'Session closed',
            duration_ms: Date.now() - start
        });

    } catch (error) {
        console.error('Close error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
            duration_ms: Date.now() - start
        });
    }
});

/**
 * GET /health
 * Health check endpoint
 */
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'playwright-automation',
        version: '4.0.0',
        activeSessions: sessions.size
    });
});

/**
 * GET /sessions
 * List active sessions
 */
app.get('/sessions', (req, res) => {
    const sessionList = Array.from(sessions.keys()).map(id => ({
        sessionId: id,
        created: sessions.get(id).created || Date.now()
    }));

    res.json({
        total: sessions.size,
        sessions: sessionList
    });
});

// Utility: Basic HTML to Markdown conversion
function htmlToMarkdown(html) {
    // Very basic conversion - for production use a library like turndown
    return html
        .replace(/<h1[^>]*>(.*?)<\/h1>/gi, '# $1\n\n')
        .replace(/<h2[^>]*>(.*?)<\/h2>/gi, '## $1\n\n')
        .replace(/<h3[^>]*>(.*?)<\/h3>/gi, '### $1\n\n')
        .replace(/<p[^>]*>(.*?)<\/p>/gi, '$1\n\n')
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<strong[^>]*>(.*?)<\/strong>/gi, '**$1**')
        .replace(/<em[^>]*>(.*?)<\/em>/gi, '*$1*')
        .replace(/<a[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/gi, '[$2]($1)')
        .replace(/<li[^>]*>(.*?)<\/li>/gi, '- $1\n')
        .replace(/<[^>]+>/g, '');  // Remove remaining tags
}

// Cleanup: Close all sessions on shutdown
process.on('SIGINT', async () => {
    console.log('\nClosing all browser sessions...');
    for (const sessionId of sessions.keys()) {
        await closeSession(sessionId);
    }
    process.exit(0);
});

// Start server
app.listen(PORT, () => {
    console.log(`Playwright Automation Service v4.0.0`);
    console.log(`Listening on port ${PORT}`);
    console.log(`Screenshot directory: ${SCREENSHOT_DIR}`);
    console.log(`Default timeout: ${DEFAULT_TIMEOUT}ms`);
});
