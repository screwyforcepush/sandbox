const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function takeScreenshots() {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  // Set viewport for consistent screenshots
  await page.setViewportSize({ width: 1920, height: 1080 });
  
  try {
    console.log('📸 Taking dashboard screenshots...');
    
    // Listen for console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log('Browser error:', msg.text());
      }
    });
    
    // Navigate to dashboard
    await page.goto('http://localhost:3001', { waitUntil: 'networkidle' });
    
    // Wait for React to render and check if app loaded
    await page.waitForTimeout(5000);
    
    // Check if React root exists
    const rootElement = await page.locator('#root').count();
    console.log('Root element found:', rootElement > 0);
    
    // Try to wait for any content
    try {
      await page.waitForSelector('body *', { timeout: 5000 });
    } catch (e) {
      console.log('No content loaded after 5 seconds');
    }
    
    // Create screenshots directory
    const screenshotsDir = path.join(__dirname, 'screenshots');
    if (!fs.existsSync(screenshotsDir)) {
      fs.mkdirSync(screenshotsDir);
    }
    
    // Take full page screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'dashboard-full.png'),
      fullPage: true 
    });
    console.log('✅ Full page screenshot saved');
    
    // Take viewport screenshot
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'dashboard-viewport.png')
    });
    console.log('✅ Viewport screenshot saved');
    
    // Try to take a screenshot of workspace cards if they exist
    const workspaceCards = await page.locator('[data-testid="workspace-card"], .MuiCard-root').first();
    if (await workspaceCards.count() > 0) {
      await workspaceCards.screenshot({ 
        path: path.join(screenshotsDir, 'workspace-card.png')
      });
      console.log('✅ Workspace card screenshot saved');
      
      // Try to expand details on first running workspace
      try {
        const expandButton = await page.locator('.MuiCard-root:has-text("Running") button[aria-label*="expand"], .MuiCard-root:has-text("Running") svg').first();
        if (await expandButton.count() > 0) {
          await expandButton.click();
          await page.waitForTimeout(2000);
          
          // Take screenshot of expanded card
          const expandedCard = await page.locator('.MuiCard-root:has(.MuiCollapse-entered)').first();
          if (await expandedCard.count() > 0) {
            await expandedCard.screenshot({
              path: path.join(screenshotsDir, 'workspace-card-expanded.png')
            });
            console.log('✅ Expanded workspace card screenshot saved');
          }
        }
      } catch (e) {
        console.log('Could not expand workspace details');
      }
    }
    
    // Take screenshot of header/toolbar
    const header = await page.locator('.MuiAppBar-root, header').first();
    if (await header.count() > 0) {
      await header.screenshot({ 
        path: path.join(screenshotsDir, 'header.png')
      });
      console.log('✅ Header screenshot saved');
    }
    
    // Test responsive design - mobile view
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'dashboard-mobile.png')
    });
    console.log('✅ Mobile screenshot saved');
    
    // Test responsive design - tablet view
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.waitForTimeout(1000);
    await page.screenshot({ 
      path: path.join(screenshotsDir, 'dashboard-tablet.png')
    });
    console.log('✅ Tablet screenshot saved');
    
    console.log('\n📁 Screenshots saved to:', screenshotsDir);
    console.log('📋 Available screenshots:');
    const files = fs.readdirSync(screenshotsDir);
    files.forEach(file => console.log(`   - ${file}`));
    
  } catch (error) {
    console.error('❌ Error taking screenshots:', error);
  } finally {
    await browser.close();
  }
}

// Run if called directly
if (require.main === module) {
  takeScreenshots().catch(console.error);
}

module.exports = { takeScreenshots };