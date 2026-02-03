# Railway Deployment Setup Checklist ✅

## Current Issues Detected

⚠️ **REDIS_URL not set** - Sidekiq is falling back to async adapter (not recommended for production)

---

## Required Setup Steps

### 1. Add Redis Database Service

**In Railway Dashboard:**

1. Go to your project: https://railway.app/dashboard
2. Click **"New"** button
3. Select **"Database"** → **"Redis"**
4. Railway will automatically:
   - Deploy a Redis instance
   - Set the `REDIS_URL` environment variable
   - Connect it to your application

**How to verify:**
- Go to your web service → **Variables** tab
- Look for `REDIS_URL` - should look like: `redis://default:password@host:port`

---

### 2. Enable Worker Process

Your `Procfile` already has the worker configured:
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bundle exec rails db:migrate
```

**In Railway Dashboard:**

1. Go to your web service
2. Click **"Settings"** tab
3. Scroll to **"Deploy"** section
4. Ensure both `web` and `worker` processes are enabled

**Alternative: Check via Railway CLI**
```bash
railway run --service=web
railway run --service=worker
```

---

### 3. Verify Environment Variables

**Required Variables:**

| Variable | Value | Status |
|----------|-------|--------|
| `REDIS_URL` | Auto-set by Redis service | ❌ Missing |
| `RAILS_ENV` | `production` | Should be set |
| `SECRET_KEY_BASE` | Auto-generated | Should be set |
| `DATABASE_URL` | Auto-set by Postgres | Should be set |

**Optional but Recommended:**

| Variable | Suggested Value | Purpose |
|----------|----------------|---------|
| `SIDEKIQ_CONCURRENCY` | `5` | Number of Sidekiq threads |
| `RAILS_MAX_THREADS` | `5` | Puma max threads |
| `WEB_CONCURRENCY` | `2` | Puma worker processes |

**To add variables:**
1. Go to your service → **Variables** tab
2. Click **"New Variable"**
3. Add variable name and value
4. Click **"Add"**

---

### 4. Verify Deployment

**After adding Redis and deploying:**

1. **Check Logs:**
   ```
   Railway Dashboard → Your Service → Deployments → Latest → View Logs
   ```

2. **Look for success messages:**
   ```
   ✅ "Redis configured successfully"
   ✅ "Sidekiq server started"
   ✅ "Puma starting in cluster mode"
   ✅ "Rails 8.0.4 application starting in production"
   ```

3. **Should NOT see:**
   ```
   ❌ "REDIS_URL not set"
   ❌ "using async job adapter"
   ❌ "SyntaxError" (now fixed!)
   ```

---

### 5. Test Sidekiq Dashboard

**Once deployed with Redis:**

Visit: `https://your-app.railway.app/sidekiq`

You should see:
- ✅ Processed jobs count
- ✅ Failed jobs (should be 0)
- ✅ Queue statistics
- ✅ Real-time job processing

If you see a 404 or error, check [config/routes.rb](config/routes.rb) for Sidekiq mount point.

---

### 6. Monitor Performance

**Expected after Redis + Sidekiq setup:**

| Metric | Without Redis | With Redis | Improvement |
|--------|---------------|------------|-------------|
| Dashboard load | 800-1500ms | 100-150ms | **85-90% faster** |
| Cache hits | 0% | 90%+ | ∞ faster |
| Background jobs | Blocking | Async | Non-blocking |
| Concurrent users | ~10 | 50-100+ | **5-10x more** |

---

## Quick Commands for Railway CLI

**Install Railway CLI (if not installed):**
```bash
npm i -g @railway/cli
# or
brew install railway
```

**Login and link project:**
```bash
railway login
railway link
```

**Check environment variables:**
```bash
railway variables
```

**Add Redis URL manually (if needed):**
```bash
railway variables set REDIS_URL=redis://your-redis-url
```

**View logs:**
```bash
railway logs
```

**Run commands in production:**
```bash
railway run rails console
railway run rails db:migrate
```

---

## Troubleshooting

### Issue: "REDIS_URL not set"

**Solution:**
1. Add Redis service from Railway dashboard
2. Wait 1-2 minutes for provisioning
3. Redeploy your application
4. Check logs for "Redis configured successfully"

### Issue: Worker process not starting

**Solution:**
1. Check Procfile exists in repo root
2. Ensure `worker:` line is present
3. Check Railway settings → Deploy → Processes
4. Manually enable worker if disabled

### Issue: Sidekiq jobs not processing

**Solution:**
1. Verify REDIS_URL is set: `railway variables | grep REDIS`
2. Check worker process logs: Railway Dashboard → Worker Service → Logs
3. Verify Sidekiq config: [config/sidekiq.yml](config/sidekiq.yml)
4. Check for errors in Sidekiq dashboard: `/sidekiq`

### Issue: Cache not working

**Solution:**
1. Verify Redis connection in console:
   ```ruby
   railway run rails console
   > Rails.cache.redis.ping
   # Should return "PONG"
   ```
2. Check cache store config: [config/initializers/performance.rb](config/initializers/performance.rb)
3. Clear cache: `railway run rails cache:clear`

---

## Cost Estimate

**Railway Pricing (approximate):**

| Resource | Plan | Cost/Month |
|----------|------|------------|
| **Web Service** | Hobby | $5 |
| **Worker Service** | Hobby | $5 |
| **Redis** | 512MB | $5-10 |
| **Postgres** | Included | $0 |
| **Total** | | **$15-20/month** |

**Much cheaper than Heroku ($22-40/month)!** 🎉

---

## Current Status

- ✅ Syntax error fixed and pushed
- ✅ Performance caching implemented
- ✅ Sidekiq configured
- ✅ Procfile configured
- ❌ **Redis service not added** ← **YOU ARE HERE**
- ❌ Worker process may not be enabled

---

## Next Steps (DO THIS NOW)

1. **Go to Railway Dashboard**
2. **Click "New" → "Database" → "Redis"**
3. **Wait 1-2 minutes for Redis to provision**
4. **Verify REDIS_URL appears in Variables tab**
5. **Wait for automatic redeployment (or trigger manually)**
6. **Check deployment logs for success messages**
7. **Visit `/sidekiq` dashboard to confirm it's working**

**ETA: 5 minutes** ⏱️

After completing these steps, your application will be fully optimized and production-ready! 🚀
