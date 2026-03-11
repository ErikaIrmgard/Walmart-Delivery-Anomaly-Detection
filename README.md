# Walmart Delivery Anomaly Detection and Risk Scoring

## Overview
This project investigates missing items in Walmart delivery operations and develops a machine learning model to identify orders with a higher probability of delivery inconsistencies.

The analysis combines exploratory data analysis (EDA), operational diagnostics, anomaly/risk detection, and business-oriented dashboarding in Power BI.

---

## Business Problem
Large-scale delivery operations are exposed to operational failures such as missing items in customer orders. These events generate financial losses, reduce customer satisfaction, and may indicate logistical inefficiencies or anomalous delivery patterns.

The objective of this project is to:
- identify operational patterns associated with missing items,
- understand which regions, product categories, time periods, and drivers are more exposed,
- build a machine learning model to estimate delivery risk,
- support monitoring and prioritization of high-risk orders.

---

## Project Goals
- Explore missing item patterns across the delivery operation
- Quantify operational and financial impact
- Identify factors associated with missing-item events
- Build a risk scoring model for delivery orders
- Translate insights into actionable business recommendations
- Present findings through an interactive Power BI dashboard

---

## Dataset
The project uses Walmart delivery-related data, including information about:
- orders,
- customers,
- drivers,
- products,
- missing items.

Key variables used in the analysis include:
- region,
- delivery hour,
- order amount,
- product category,
- driver information,
- missing items per order.

---

## Main Analytical Steps

### 1. Data Preparation
- Data quality checks
- Feature cleaning and type corrections
- Integration of fact and dimension tables
- Creation of derived variables such as:
  - missing rate,
  - total items per order,
  - delivery hour,
  - risk levels.

### 2. Exploratory Data Analysis
The EDA focused on identifying operational patterns associated with missing items:
- missing rate by region,
- missing rate by product category,
- missing rate by delivery hour,
- driver-level patterns,
- hierarchical decomposition of missing-item events,
- operational heatmaps by region and hour.

### 3. Risk Modeling
A machine learning classification approach was used to estimate the probability of missing-item occurrences in delivery orders.

The final model generates:
- a risk probability score for each order,
- risk levels such as Low, Medium, and High Risk.

### 4. Business Dashboard
An interactive Power BI dashboard was developed with four sections:
1. Overview of the problem
2. Exploratory analysis (EDA)
3. Risk model interpretation
4. Conclusions and operational recommendations

---

## Key Findings
- Missing-item events are not uniformly distributed across the operation.
- Certain regions, product categories, hours of the day, and drivers concentrate a higher volume of occurrences.
- The category **Supermarket** accounts for a large share of operational losses.
- The machine learning model successfully differentiates low-risk and high-risk orders.
- Orders classified as **High Risk** present substantially higher missing-item incidence and concentrate a relevant share of estimated financial loss.

---

## Model Output
The model assigns a risk score to each order and classifies orders into risk groups.

This allows the operation to:
- prioritize suspicious or higher-risk orders,
- reinforce controls in critical regions and time windows,
- support targeted audits and operational monitoring.

---

## Dashboard Pages
### 1. Overview
High-level summary of:
- total orders,
- orders with missing items,
- total missing items,
- estimated loss,
- key operational concentrations.

### 2. Exploratory Analysis
Operational exploration of:
- regions,
- categories,
- delivery hours,
- drivers,
- hierarchical decomposition of missing-item events.

### 3. Risk Model
Interpretation of:
- risk score distribution,
- risk level segmentation,
- missing-item rate by risk level,
- financial loss by risk level.

### 4. Conclusions and Recommendations
Final synthesis of:
- operational insights,
- model usefulness,
- recommendations for monitoring and loss mitigation.

---

## Tools and Technologies
- Python
- Pandas
- NumPy
- Scikit-learn
- Jupyter Notebook
- Power BI

---

## Repository Structure
```text
notebooks/   -> analysis and modeling notebooks
dashboard/   -> Power BI dashboard
images/      -> dashboard screenshots
data/        -> optional data notes or data dictionary
