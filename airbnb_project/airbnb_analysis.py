

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import warnings
warnings.filterwarnings('ignore')

# ── STEP 1: LOAD DATA ────────────────────────────────────
df = pd.read_csv('airbnb_listings.csv')
print("=== RAW DATA ===")
print(f"Shape         : {df.shape}")
print(f"Missing values:\n{df.isnull().sum()}\n")

# ── STEP 2: CLEAN DATA ───────────────────────────────────
# Remove missing prices and outliers
df = df.dropna(subset=['price'])
df = df[df['price'] > 0]
df = df[df['price'] < 1000]   # outlier cap

# Fill remaining missing values
df['bedrooms']             = df['bedrooms'].fillna(df['bedrooms'].median())
df['review_scores_rating'] = df['review_scores_rating'].fillna(df['review_scores_rating'].mean())

# Create new useful columns
df['is_superhost']     = df['host_is_superhost'].map({'t': 1, 'f': 0})
df['price_per_person'] = df['price'] / df['accommodates']

print("=== CLEANED DATA ===")
print(f"Rows     : {len(df)}")
print(f"Avg Price: £{df['price'].mean():.2f}\n")

# ── STEP 3: BUSINESS QUESTIONS ───────────────────────────

# Q1: Which neighbourhood is most expensive?
neigh_price = df.groupby('neighbourhood')['price'].mean().sort_values(ascending=False).round(2)
print("Q1 — Avg Price by Neighbourhood:\n", neigh_price.to_string(), "\n")

# Q2: Which room type commands highest price?
room_price = df.groupby('room_type')['price'].mean().sort_values(ascending=False).round(2)
print("Q2 — Avg Price by Room Type:\n", room_price.to_string(), "\n")

# Q3: Does more bedrooms = higher price?
bed_price = df.groupby('bedrooms')['price'].mean().round(2)
print("Q3 — Avg Price by Bedrooms:\n", bed_price.to_string(), "\n")

# Q4: Do superhosts charge more?
super_price = df.groupby('is_superhost')['price'].mean().round(2)
print(f"Q4 — Superhost Premium:")
print(f"   Regular host : £{super_price[0]:.2f}")
print(f"   Superhost    : £{super_price[1]:.2f}\n")

# Q5: Find undervalued listings
# Definition: price 25% below neighbourhood average + rating >= 4.5 + 10+ reviews
neigh_avg            = df.groupby('neighbourhood')['price'].mean()
df['neigh_avg']      = df['neighbourhood'].map(neigh_avg)
df['is_undervalued'] = (
    (df['price'] < df['neigh_avg'] * 0.75) &
    (df['review_scores_rating'] >= 4.5)    &
    (df['number_of_reviews'] >= 10)
)
undervalued = df[df['is_undervalued']].sort_values('review_scores_rating', ascending=False)
print(f"Q5 — Undervalued Listings Found: {len(undervalued)}")
print(undervalued[['neighbourhood','room_type','price','neigh_avg','review_scores_rating']].head(10).to_string(index=False))

# ── STEP 4: SAVE RESULTS ─────────────────────────────────
undervalued.to_csv('undervalued_listings.csv', index=False)
print("\nUndervalued listings saved!")
