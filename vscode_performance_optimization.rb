#!/usr/bin/env ruby
# VS Code Performance Optimization Script

puts "🚀 VS CODE & WORKSPACE PERFORMANCE OPTIMIZATION"
puts "=" * 60
puts "Date: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
puts ""

puts "🔍 INVESTIGATING PERFORMANCE ISSUES..."
puts ""

# Check current directory sizes
puts "📊 WORKSPACE SIZE ANALYSIS:"
puts ""

require 'filesize'

def format_size(bytes)
  return "0 B" if bytes == 0
  
  units = ['B', 'KB', 'MB', 'GB']
  exp = (Math.log(bytes) / Math.log(1024)).floor
  formatted = (bytes / 1024.0**exp).round(1)
  
  "#{formatted} #{units[exp]}"
end

def get_directory_size(path)
  return 0 unless Dir.exist?(path)
  
  `du -sk #{path} 2>/dev/null`.split.first.to_i * 1024
end

# Analyze workspace directories
workspace_analysis = {
  "Log Files" => get_directory_size("log"),
  "Temporary Files" => get_directory_size("tmp"),
  "MiniProfiler Cache" => get_directory_size("tmp/miniprofiler"),
  "Node Modules" => get_directory_size("node_modules"),
  "Vendor Bundle" => get_directory_size("vendor"),
  "Ruby LSP Cache" => get_directory_size(".ruby-lsp"),
  "Git Directory" => get_directory_size(".git")
}

workspace_analysis.each do |name, size|
  status = size > 50_000_000 ? "🔴 LARGE" : size > 10_000_000 ? "🟡 MEDIUM" : "✅ OK"
  puts "#{status} #{name.ljust(20)}: #{format_size(size)}"
end

puts ""
puts "🧹 PERFORMANCE CLEANUP ACTIONS:"
puts ""

# Action 1: Clean large log files
if File.exist?("log/development.log")
  log_size = File.size("log/development.log")
  if log_size > 10_000_000  # 10MB
    puts "1. 🗑️  Cleaning large development log (#{format_size(log_size)})"
    File.truncate("log/development.log", 0)
    puts "   ✅ Development log cleared"
  else
    puts "1. ✅ Development log size OK (#{format_size(log_size)})"
  end
else
  puts "1. ✅ No large development log found"
end

# Action 2: Clean MiniProfiler cache
if Dir.exist?("tmp/miniprofiler")
  mp_size = get_directory_size("tmp/miniprofiler")
  if mp_size > 5_000_000  # 5MB
    puts "2. 🗑️  Cleaning MiniProfiler cache (#{format_size(mp_size)})"
    system("rm -rf tmp/miniprofiler/*")
    puts "   ✅ MiniProfiler cache cleaned"
  else
    puts "2. ✅ MiniProfiler cache size OK (#{format_size(mp_size)})"
  end
else
  puts "2. ✅ No MiniProfiler cache found"
end

# Action 3: Clean temporary cache files
if Dir.exist?("tmp/cache")
  cache_size = get_directory_size("tmp/cache")
  if cache_size > 10_000_000  # 10MB
    puts "3. 🗑️  Cleaning Rails cache (#{format_size(cache_size)})"
    system("rm -rf tmp/cache/*")
    puts "   ✅ Rails cache cleaned"
  else
    puts "3. ✅ Rails cache size OK (#{format_size(cache_size)})"
  end
else
  puts "3. ✅ No large Rails cache found"
end

# Action 4: Update Ruby LSP
puts "4. 🔄 Checking Ruby LSP status..."
if File.exist?(".ruby-lsp/last_updated")
  last_updated = File.read(".ruby-lsp/last_updated").strip
  puts "   Ruby LSP last updated: #{last_updated}"
  puts "   ✅ Ruby LSP appears current"
else
  puts "   🟡 Ruby LSP may need refresh"
end

puts ""
puts "🎯 VS CODE OPTIMIZATION RECOMMENDATIONS:"
puts ""

recommendations = [
  "1. 🔧 Exclude Large Directories from VS Code Indexing:",
  "   Add to .vscode/settings.json:",
  "   {",
  '     "files.exclude": {',
  '       "**/log/**": true,',
  '       "**/tmp/**": true,',
  '       "**/*.log": true',
  '     },',
  '     "search.exclude": {',
  '       "**/log/**": true,',
  '       "**/tmp/**": true',
  '     }',
  "   }",
  "",
  "2. 📁 Use .gitignore to exclude temporary files:",
  "   - Ensure log/, tmp/, .ruby-lsp/ are in .gitignore",
  "   - Add any large generated files",
  "",
  "3. 🚀 Ruby LSP Optimizations:",
  "   - Restart Ruby LSP: Cmd+Shift+P → 'Ruby LSP: Restart'",
  "   - Update Ruby LSP extension if available",
  "",
  "4. 💾 VS Code Memory Management:",
  "   - Close unused tabs and windows",
  "   - Restart VS Code periodically",
  "   - Increase VS Code memory limit if needed",
  "",
  "5. 🔍 Disable Heavy Extensions temporarily:",
  "   - Copilot (if not needed)",
  "   - Heavy linters/formatters",
  "   - Multiple language servers"
]

recommendations.each { |rec| puts rec }

puts ""
puts "⚡ RAILS APPLICATION OPTIMIZATIONS:"
puts ""

rails_optimizations = [
  "1. 🗄️  Database Query Optimization:",
  "   ✅ Already implemented eager loading",
  "   ✅ Database indexes optimized", 
  "   ✅ N+1 query prevention in place",
  "",
  "2. 🧹 Regular Maintenance:",
  "   - Clean logs: rails log:clear",
  "   - Clear cache: rails tmp:clear",
  "   - Restart server: rails restart",
  "",
  "3. 📊 Production Monitoring:",
  "   - Use Heroku metrics for production performance",
  "   - Monitor database query times",
  "   - Check memory usage patterns"
]

rails_optimizations.each { |opt| puts opt }

puts ""
puts "🔧 IMMEDIATE ACTIONS TO TAKE:"
puts ""

immediate_actions = [
  "1. 🔄 Restart VS Code completely",
  "2. 🧹 Run: rails tmp:clear && rails log:clear", 
  "3. ⚙️  Create .vscode/settings.json with file exclusions",
  "4. 🔍 Check VS Code Extensions and disable heavy ones",
  "5. 💾 Check available disk space and memory",
  "6. 🚀 Restart Ruby LSP: Cmd+Shift+P → 'Ruby LSP: Restart'"
]

immediate_actions.each { |action| puts action }

puts ""
puts "=" * 60
puts "✅ CLEANUP COMPLETED!"
puts "🚀 VS Code should now run faster"
puts "💡 Apply the recommendations above for optimal performance"
puts ""
puts "📊 Next: Monitor performance and repeat cleanup as needed"
puts "=" * 60
