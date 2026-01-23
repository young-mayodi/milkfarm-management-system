# MilkyWay Farm Management System

A comprehensive Ruby on Rails application for managing dairy farm operations, tracking milk production, and recording sales data.

## Features

### Core Functionality
- **Farm Management**: Register and manage multiple dairy farms
- **Cow Registry**: Track individual cows with detailed information
- **Production Records**: Daily milk production tracking (morning, noon, evening)
- **Sales Records**: Track milk sales with payment method breakdown
- **Dashboard**: Overview of farm operations with key metrics

### Advanced Features
- **Reporting & Analytics**: Farm summary reports and individual cow performance analysis
- **Interactive Charts**: Beautiful production charts using Chart.js for data visualization
  - Dashboard charts showing weekly trends, farm comparisons, and production vs sales
  - Farm-specific production trends and top cow performance charts  
  - Individual cow daily production breakdown with morning/noon/evening tracking
  - Weekly averages and production trend analysis
- **Production Trends**: Detailed analysis with customizable time periods and filtering
- **Data Export**: Export data to CSV format for external analysis
- **Pagination**: Efficient handling of large datasets
- **Date Filtering**: Filter records by custom date ranges
- **Responsive Design**: Modern, mobile-friendly interface using Bootstrap

## System Requirements

- Ruby 3.2.2 or higher
- Rails 8.0.4
- PostgreSQL 13 or higher
- Node.js (for asset compilation)

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup the database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. Start the server:
   ```bash
   rails server
   ```

5. Visit `http://localhost:3000`

## Database Schema

### Farms
- Name, location, contact information
- Associated cows and production records

### Cows
- Name, tag number, breed, age, status, group
- Belongs to a farm
- Has many production records

### Production Records
- Date, morning/noon/evening production amounts
- Belongs to a cow and farm
- Automatically calculates total daily production

### Sales Records
- Sale date, buyer information
- Milk volume sold, cash/M-Pesa payment breakdown
- Belongs to a farm

## Usage

### Getting Started
1. **Add Farms**: Create farm profiles with contact information
2. **Register Cows**: Add cows to farms with detailed information
3. **Record Production**: Daily milk production entry (3 sessions per day)
4. **Track Sales**: Record milk sales with payment details

### Daily Workflow
1. Morning production entry
2. Noon production entry
3. Evening production entry
4. Sales record entry (when applicable)

### Reporting
- View farm performance summaries with interactive charts
- Analyze individual cow productivity with visual trends
- Production trend analysis with customizable timeframes
- Export data for external analysis
- Filter records by date ranges

### Charts & Analytics
The system includes comprehensive visual analytics powered by Chart.js:

#### Dashboard Charts
- **Weekly Production Trend**: Line chart showing overall production trends
- **Farm Comparison**: Doughnut chart comparing monthly production by farm
- **Production vs Sales**: Line chart comparing daily production against sales

#### Farm Detail Charts
- **Daily Production Trend**: 30-day production trend for the farm
- **Top Producing Cows**: Bar chart showing best performing cows

#### Cow Detail Charts
- **Daily Production Breakdown**: Multi-line chart showing morning, noon, evening, and total production
- **Weekly Averages**: Bar chart showing weekly production averages

#### Reports Section
- **Farm Summary Report**: Production comparison charts and trend analysis
- **Cow Summary Report**: Top producers and average production comparisons
- **Production Trends**: Interactive charts with farm/cow/time filtering

## Technology Stack

- **Backend**: Ruby on Rails 8.0.4
- **Database**: PostgreSQL
- **Frontend**: ERB templates with Bootstrap 5
- **Charts**: Chart.js for interactive data visualization
- **JavaScript**: Stimulus (Hotwire) for enhanced interactivity
- **Pagination**: Kaminari gem
- **Styling**: Bootstrap 5 with custom CSS
- **Pagination**: Kaminari gem
- **Styling**: Bootstrap CDN
- **Icons**: Bootstrap Icons

## Development

### Running Tests
```bash
rails test
```

### Database Operations
```bash
# Reset database
rails db:reset

# Generate sample data
rails db:seed
```

### Code Quality
```bash
# Run linter
bundle exec rubocop

# Security scan
bundle exec brakeman
```

## Sample Data

The system comes with pre-seeded sample data:
- 2 Farms (BAMA DAIRY FARM, SUNSHINE DAIRY)
- 25+ Cows with realistic information
- 580+ Production records spanning several months
- 20+ Sales records with varied payment methods

## Features in Detail

### Dashboard
- Quick overview of farms, cows, and recent activity
- Key performance indicators
- Recent production and sales summaries

### Farm Management
- Farm registration with location and contact details
- View farm-specific cows and production records
- Farm performance metrics

### Cow Management
- Individual cow profiles with breed, age, and status
- Production history and performance tracking
- Group-based organization

### Production Tracking
- Three daily recording sessions (morning, noon, evening)
- Automatic total calculation
- Date-based filtering and search

### Sales Management
- Record milk sales with buyer information
- Track payment methods (cash, M-Pesa)
- Calculate pricing per liter
- Revenue tracking and analysis

### Reporting
- Farm summary reports with 30-day performance
- Individual cow productivity analysis
- Data export capabilities
- Performance visualization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is available under the MIT License.

## Support

For support or questions, please refer to the documentation or create an issue in the repository.
