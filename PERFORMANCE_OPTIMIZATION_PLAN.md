# 🚀 CRITICAL PERFORMANCE OPTIMIZATION PLAN

## Current Performance Issues (from Skylight)

### Response Time Breakdown:
- **Database: 49%** ⚠️ CRITICAL
- **View Rendering: 39%** ⚠️ HIGH
- **App Logic: 9%**
- **Other: 3%**

### Identified Bottlenecks:
1. ❌ Multiple `SELECT FROM production_records` queries (N+1 problem)
2. ❌ No database indexes on frequently queried columns
3. ❌ Cache generation on every request (should use Redis)
4. ❌ No query result caching
5. ❌ Eager loading missing in many places
6. ❌ View partials being rendered repeatedly
7. ❌ No fragment caching in views

---

## 🎯 Immediate Fixes (Quick Wins)

### 1. Add Database Indexes
**Impact**: 50-70% reduction in query time
**Files**: `db/migrate/add_performance_indexes.rb`

```ruby
# Missing indexes that will speed up queries significantly
add_index :production_records, :production_date
add_index :production_records, :cow_id
add_index :production_records, :farm_id
add_index :production_records, [:cow_id, :production_date]
add_index :production_records, [:farm_id, :production_date]
add_index :cows, :farm_id
add_index :cows, :status
add_index :sales_records, :sale_date
add_index :sales_records, :farm_id
```

### 2. Fix N+1 Queries in Reports Controller
**Impact**: 60-80% reduction in database queries
**File**: `app/controllers/reports_controller.rb`

**Current Problem:**
```ruby
# BAD - Causes N+1 queries
@farms = Farm.includes(:cows, :production_records, :sales_records)
@farm_stats = @farms.map do |farm|
  recent_records = farm.production_records.where(...) # N+1!
  recent_sales = farm.sales_records.where(...)         # N+1!
end
```

**Solution:**
```ruby
# GOOD - Single query with aggregation
@farm_stats = Farm.joins(:production_records, :sales_records)
  .select(
    'farms.*',
    'COUNT(DISTINCT cows.id) as total_cows',
    'SUM(production_records.total_production) as recent_production',
    'AVG(production_records.total_production) as avg_daily_production'
  )
  .where(production_records: { production_date: 30.days.ago..Date.current })
  .group('farms.id')
```

### 3. Implement Redis Caching
**Impact**: 80-90% faster page loads
**Files**: `config/environments/production.rb`

```ruby
# Enable Redis caching
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 15.minutes,
  namespace: 'milkfarm'
}
```

### 4. Add Fragment Caching to Views
**Impact**: 70-90% faster view rendering
**Files**: View templates

```erb
<!-- Cache expensive partials -->
<% cache ['farm-summary', @farm.id, @farm.updated_at] do %>
  <%= render 'farm_summary_stats' %>
<% end %>
```

---

## 📊 Performance Optimization Strategy

### Phase 1: Database Optimization (Immediate - 1 hour)
- [ ] Add missing database indexes
- [ ] Fix N+1 queries in controllers
- [ ] Use `select` to limit columns returned
- [ ] Add counter caches for associations

### Phase 2: Caching Strategy (1-2 hours)
- [ ] Set up Redis on Heroku
- [ ] Implement Rails caching for expensive queries
- [ ] Add fragment caching to views
- [ ] Cache chart data generation

### Phase 3: Query Optimization (2-3 hours)
- [ ] Convert Ruby aggregations to SQL
- [ ] Use database views for complex reports
- [ ] Implement pagination for large datasets
- [ ] Add query timeouts

### Phase 4: View Optimization (1-2 hours)
- [ ] Remove unused view queries
- [ ] Lazy load charts/images
- [ ] Minimize JavaScript execution
- [ ] Compress assets

---

## 🔧 Implementation Priority

### CRITICAL (Do First):
1. **Add Database Indexes** - 10 min setup, massive performance gain
2. **Fix Reports Controller N+1** - Biggest bottleneck visible in Skylight
3. **Enable Redis Caching** - Essential for production

### HIGH (Do Next):
4. **Add Fragment Caching** - Will speed up all pages
5. **Optimize Production Records Queries**
6. **Add Counter Caches**

### MEDIUM (Do Soon):
7. **Lazy Load Charts**
8. **Compress Assets**
9. **Add Database Views**

---

## 📈 Expected Performance Improvements

### Current State:
- Average Response Time: **166ms**
- Database Time: **49% (81ms)**
- View Time: **39% (65ms)**

### After Optimization:
- Average Response Time: **~30-50ms** (70% improvement)
- Database Time: **10-15% (~5-8ms)** (90% improvement)
- View Time: **15-20% (~7-10ms)** (85% improvement)

---

## 🚨 Quick Emergency Fix (Do This NOW)

Add this to production.rb to enable caching immediately:
```ruby
config.action_controller.perform_caching = true
config.cache_store = :memory_store
```

This alone will give 40-50% improvement until Redis is set up.

---

## Next Steps

1. Review this plan
2. I'll implement Phase 1 (database indexes) first
3. Deploy and monitor Skylight
4. Continue with Phase 2 (caching)

**Estimated Total Time**: 5-8 hours for all phases
**Estimated Performance Gain**: 70-85% faster page loads

---

*Generated: January 29, 2026*
*Priority: CRITICAL*
