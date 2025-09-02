#!/usr/bin/env node

const { ClaudeAuth } = require('@vibe-kit/auth/node');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

async function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, (answer) => {
      resolve(answer);
    });
  });
}

async function main() {
  try {
    console.log('🔐 Claude Authentication Setup');
    console.log('==============================\n');

    // Check for existing token
    const existingToken = await ClaudeAuth.getValidToken();
    
    if (existingToken) {
      console.log('✅ Valid Claude token found!');
      
      const useExisting = await question('\nUse existing token? (y/n): ');
      if (useExisting.toLowerCase() === 'y') {
        console.log('\n📋 Token exported. You can now use it with Claude Code.');
        console.log(`\nExport with: export CLAUDE_CODE_OAUTH_TOKEN="${existingToken}"`);
        
        // Return token for shell script to capture
        process.stdout.write(`\nTOKEN:${existingToken}`);
        rl.close();
        return;
      }
    }

    console.log('\n🌐 Starting OAuth authentication flow...');
    console.log('\nThis will open your browser for authentication.');
    console.log('After authorizing, you\'ll see an authentication code.');
    console.log('Copy the ENTIRE code (format: code#state) and paste it below.\n');

    await question('Press Enter to open browser...');

    // Start authentication with timeout and better error handling
    console.log('\n⏳ Starting authentication process...');
    console.log('   If the browser doesn\'t open automatically, please check your terminal.');
    console.log('   The authentication process may take a few moments.\n');
    
    try {
      await ClaudeAuth.authenticate();
    } catch (error) {
      if (error.message.includes('timeout') || error.message.includes('cancelled')) {
        console.error('\n⏱️  Authentication timed out or was cancelled');
        console.error('   Please try again. Make sure to complete the browser authentication flow.');
      } else {
        console.error('\n❌ Authentication failed:', error.message);
        console.error('   Please check your internet connection and try again.');
      }
      throw error;
    }

    // Get the newly authenticated token
    const newToken = await ClaudeAuth.getValidToken();
    
    if (newToken) {
      console.log('\n✅ Authentication successful!');
      console.log('\n📋 Token has been saved to ~/.vibekit/claude-oauth-token.json');
      console.log(`\nExport with: export CLAUDE_CODE_OAUTH_TOKEN="${newToken}"`);
      
      // Return token for shell script to capture
      process.stdout.write(`\nTOKEN:${newToken}`);
    } else {
      console.error('\n❌ Authentication failed - no token received');
      process.exit(1);
    }

    rl.close();
  } catch (error) {
    console.error('\n❌ Authentication error:', error.message);
    rl.close();
    process.exit(1);
  }
}

// Handle cleanup
process.on('SIGINT', () => {
  console.log('\n\n⚠️  Authentication cancelled');
  rl.close();
  process.exit(1);
});

main();