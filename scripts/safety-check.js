#!/usr/bin/env node
/**
 * Safety Tripwire Script
 * Prevents AI agents from accidentally using production credentials
 * Run this BEFORE any other verification steps
 */

const fs = require('fs');
const path = require('path');

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const RESET = '\x1b[0m';

let hasErrors = false;

function error(msg) {
    console.error(`${RED}❌ SAFETY VIOLATION: ${msg}${RESET}`);
    hasErrors = true;
}

function warn(msg) {
    console.warn(`${YELLOW}⚠️  WARNING: ${msg}${RESET}`);
}

function pass(msg) {
    console.log(`${GREEN}✅ ${msg}${RESET}`);
}

// Load .env.local or .env
function loadEnv() {
    const envPath = path.join(process.cwd(), '.env.local');
    const envFallback = path.join(process.cwd(), '.env');

    const envFile = fs.existsSync(envPath) ? envPath :
        fs.existsSync(envFallback) ? envFallback : null;

    if (!envFile) {
        warn('No .env.local or .env file found');
        return {};
    }

    const content = fs.readFileSync(envFile, 'utf-8');
    const env = {};

    content.split('\n').forEach(line => {
        const match = line.match(/^([^=]+)=(.*)$/);
        if (match) {
            env[match[1].trim()] = match[2].trim().replace(/^["']|["']$/g, '');
        }
    });

    return env;
}

function checkSafety() {
    console.log('\n🛡️  SAFETY TRIPWIRE CHECK\n');

    const env = loadEnv();

    // 1. Check Supabase URL is NOT production
    const supabaseUrl = env.NEXT_PUBLIC_SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || '';

    if (supabaseUrl.includes('supabase.co') && !supabaseUrl.includes('localhost')) {
        // Check if it's a known test/dev project or production
        const projectRef = supabaseUrl.match(/https:\/\/([^.]+)\.supabase\.co/)?.[1];

        // Add your PROD project ref here to block it
        const PROD_PROJECT_REFS = [
            // Add production project ref here, e.g.:
            // 'abc123prodref'
        ];

        if (PROD_PROJECT_REFS.includes(projectRef)) {
            error(`Supabase URL points to PRODUCTION project: ${projectRef}`);
        } else {
            warn(`Using remote Supabase: ${supabaseUrl.substring(0, 40)}...`);
            pass('Not a known production project (add to PROD_PROJECT_REFS if this is prod)');
        }
    } else if (supabaseUrl.includes('localhost') || supabaseUrl.includes('127.0.0.1')) {
        pass('Supabase URL is local');
    } else {
        warn('Supabase URL not detected');
    }

    // 2. Check Stripe key is TEST mode
    const stripeSecretKey = env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET_KEY || '';

    if (stripeSecretKey.startsWith('sk_live_')) {
        error('Stripe key is LIVE/PRODUCTION! Must use sk_test_...');
    } else if (stripeSecretKey.startsWith('sk_test_')) {
        pass('Stripe key is test mode');
    } else if (stripeSecretKey) {
        warn('Stripe key format not recognized');
    } else {
        warn('Stripe secret key not found');
    }

    const stripePublishableKey = env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || '';

    if (stripePublishableKey.startsWith('pk_live_')) {
        error('Stripe publishable key is LIVE/PRODUCTION! Must use pk_test_...');
    } else if (stripePublishableKey.startsWith('pk_test_')) {
        pass('Stripe publishable key is test mode');
    }

    // 3. Check Twilio creds
    const twilioAccountSid = env.TWILIO_ACCOUNT_SID || process.env.TWILIO_ACCOUNT_SID || '';
    const twilioAuthToken = env.TWILIO_AUTH_TOKEN || process.env.TWILIO_AUTH_TOKEN || '';

    // Twilio test credentials start with AC for account SID
    // Test mode uses specific test SID: ACxxxxx... 
    if (twilioAccountSid && twilioAuthToken) {
        // Check if using Twilio test credentials
        // Test account SID for Twilio: Must start with AC and be 34 chars
        if (twilioAccountSid.startsWith('AC') && twilioAccountSid.length === 34) {
            pass('Twilio Account SID format valid');
            // Note: Can't easily distinguish test vs prod Twilio - warn only
            warn('Verify Twilio is in test mode manually if doing real SMS/calls');
        } else {
            warn('Twilio Account SID format unusual');
        }
    } else {
        warn('Twilio credentials not found');
    }

    // 4. Summary
    console.log('\n' + '─'.repeat(50));

    if (hasErrors) {
        console.error(`\n${RED}🚨 SAFETY CHECK FAILED - DO NOT PROCEED${RESET}\n`);
        process.exit(1);
    } else {
        pass('All safety checks passed\n');
        process.exit(0);
    }
}

checkSafety();
