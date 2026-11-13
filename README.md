# 🏨 AtliQ Hospitality Analytics | End-to-End Data Analytics Project

An end-to-end hospitality analytics project using **Microsoft Excel, SQL, Power BI, and Tableau** to analyze hotel booking performance, revenue, occupancy, cancellations, customer ratings, and business trends.

## 📌 Project Overview

This project focuses on analyzing the business performance of AtliQ Hotels, a hospitality group operating across multiple cities.

The analysis covers hotel bookings from **May 1, 2022, to July 31, 2022**, helping management understand revenue performance, booking trends, occupancy rates, cancellation patterns, and revenue leakage.

The project uses multiple data analytics tools to transform raw hospitality data into meaningful insights and interactive dashboards that support data-driven business decisions.

## 🎯 Business Problem

AtliQ Hotels experienced challenges related to:
- High booking cancellations and no-shows.
- Revenue leakage from unsuccessful bookings.
- Differences in RevPAR and occupancy across cities.
- Fluctuations in weekly and daily demand.
- Understanding booking platform performance and customer ratings.

The objective is to identify business performance gaps and provide actionable recommendations to improve hotel revenue and operational efficiency.

## 🎯 Project Objectives

- Analyze overall hotel booking and revenue performance.
- Calculate and monitor key hospitality KPIs.
- Compare occupancy and RevPAR across different cities.
- Identify cancellation and no-show patterns.
- Analyze revenue leakage across hotel properties.
- Evaluate booking platform performance.
- Compare weekday and weekend demand.
- Analyze weekly revenue and occupancy fluctuations.
- Build interactive dashboards using multiple analytics tools.

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| Microsoft Excel | Data analysis, Pivot Tables, KPI calculations and dashboards |
| SQL (MySQL) | Data importing, cleaning, querying and business analysis |
| Power BI | Interactive dashboards and data visualization |
| Tableau | Data visualization and dashboard development |
| CSV / Excel | Dataset storage and management |

## 📂 Project Structure

```text
AtliQ-Hospitality-Analytics/
│
├── Dataset/
│   ├── dim_date.csv
│   ├── dim_hotels.csv
│   ├── dim_rooms.csv
│   ├── fact_bookings.csv
│   └── fact_aggregated_bookings.csv
│
├── Excel/
│   └── Excel Project.xlsx
│
├── SQL/
│   └── SQL_Project.sql
│
├── PowerBI/
│   └── Power_Bi_Project.pbix
│
├── Tableau/
│   └── Tableau Project.twbx
│
├── Documentation/
│   ├── Objectives & KPIs.pptx
│   ├── KPIs and Formulas.pdf
│   ├── Metrics List.xlsx
│   └── Hospitality Metadata.txt
│
├── Screenshots/
│
└── README.md
```

## 📊 Dataset Overview

The project uses five datasets:

| Dataset | Description |
|---|---|
| dim_date | Date, week number and day type information |
| dim_hotels | Hotel properties, categories and cities |
| dim_rooms | Room IDs and room classifications |
| fact_bookings | Booking details, revenue, ratings and booking status |
| fact_aggregated_bookings | Successful bookings and available room capacity |

**Dataset Coverage:**
- 25 hotel properties
- 4 cities
- 134,590 bookings
- 92-day analysis period
- 5 datasets

## 📈 Key Performance Indicators (KPIs)

The following hospitality metrics were calculated and analyzed:

| KPI | Description |
|---|---|
| Revenue | Total realized revenue |
| Total Bookings | Number of hotel bookings |
| Realisation % | Percentage of bookings completed |
| Cancellation % | Percentage of cancelled bookings |
| No-Show Rate | Percentage of bookings with no guest arrival |
| Revenue Leakage | Difference between generated and realized revenue |
| Occupancy % | Percentage of available room capacity booked |
| ADR | Average Daily Rate |
| RevPAR | Revenue Per Available Room |
| Average Rating | Average customer rating |
| DBRN | Daily Booked Room Nights |
| DSRN | Daily Sellable Room Nights |
| DURN | Daily Utilized Room Nights |

## 🔍 Analysis & Dashboard Overview

### 1. Microsoft Excel

- Data analysis using Pivot Tables.
- KPI calculations and performance summaries.
- Revenue and booking analysis.
- City-wise occupancy and RevPAR comparisons.
- Weekly and daily performance analysis.
- Interactive dashboards with filters.

### 2. SQL (MySQL)

- Database creation and table management.
- Data importing and cleaning.
- Handling text inconsistencies and data quality checks.
- Aggregate functions and Common Table Expressions (CTEs).
- Joins across fact and dimension tables.
- Window functions and ranking.
- Business KPI calculations.
- Revenue leakage and property performance analysis.

### 3. Power BI

- Interactive hospitality performance dashboards.
- KPI cards and performance indicators.
- City-wise revenue and occupancy analysis.
- Booking platform analysis.
- Revenue leakage analysis.
- Weekly and daily performance trends.
- Weekday versus weekend comparisons.
- Data visualization and interactive filtering.

### 4. Tableau

- Hospitality data visualization.
- Dashboard development using the packaged Tableau workbook.
- Exploration of hotel performance metrics.

## 📊 Key Business Insights

Based on the project dashboards:

**1. Revenue Performance**
- Total realized revenue reached ₹1,708.8 million.
- Total bookings reached 134,590.

**2. Booking Performance**
- 70.1% realization rate.
- 24.8% cancellation rate.
- 5.0% no-show rate.

**3. Revenue Leakage**
- Approximately ₹298.8 million in revenue leakage was identified.
- Property-level analysis highlights the top five properties with the highest revenue leakage.

**4. Occupancy Performance**
- Booked occupancy: 57.9%.
- Realized occupancy: 40.6%.
- Weekend occupancy: 73.6%.
- Weekday occupancy: 51.3%.

**5. City-wise Performance**
- Mumbai recorded the highest RevPAR at approximately ₹8,907.
- Hyderabad recorded the lowest RevPAR at approximately ₹5,414.

**6. Customer Experience**
- Average guest rating: 3.62.
- Guest ratings were analyzed across different star-rating categories.

## 💡 Business Recommendations

- Improve cancellation management strategies to reduce revenue leakage.
- Focus on cities and properties with lower RevPAR.
- Develop weekend and weekday-specific pricing strategies.
- Monitor booking platforms to understand booking share and cancellation behavior.
- Improve operational planning using daily and weekly occupancy trends.
- Monitor customer ratings to identify opportunities for improving guest experience.

## 🚀 Future Improvements

- Develop automated reporting and dashboard refresh workflows.
- Implement hotel demand forecasting using Python.
- Build predictive models for booking cancellations.
- Perform deeper customer segmentation.
- Create automated business performance reports.
- Integrate SQL, Power BI and Python for advanced analytics.

## 📁 Project Resources

The repository includes:
- Excel workbook containing analysis and dashboards.
- SQL script containing database operations and analytical queries.
- Power BI dashboard file.
- Tableau packaged workbook.
- Five source datasets.
- KPI documentation and project objectives.

## 👨‍💻 Author

**Sriram Degari**

Aspiring Data Analyst | SQL | Power BI | Excel | Tableau | Python

🔗 **LinkedIn:** https://www.linkedin.com/in/sriram-degari-b7272633a

💻 **GitHub:** https://github.com/sriramdegari20

---

⭐ If you find this project interesting, feel free to explore the repository and share your feedback!

**#DataAnalytics #HospitalityAnalytics #SQL #PowerBI #Excel #Tableau #DataVisualization #BusinessIntelligence**
