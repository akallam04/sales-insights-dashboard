"""
dashboard/app.py
----------------
AtliQ Hardware — Sales Insights Dashboard

Run locally:
    streamlit run dashboard/app.py

Deploy:
    Push to GitHub, connect repo on share.streamlit.io, set secrets to match .env.
"""

import sys
import os

# Resolve project root so `from dashboard.db import query` works whether
# Streamlit is launched from root or from the dashboard/ subdirectory
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import streamlit as st

from dashboard.db import query

# ---------------------------------------------------------------------------
# Page config — must be the first Streamlit call
# ---------------------------------------------------------------------------
st.set_page_config(
    page_title="AtliQ Hardware — Sales Insights",
    page_icon="📊",
    layout="wide",
)

# ---------------------------------------------------------------------------
# Data loading — cached so it only hits MySQL once per session
# ---------------------------------------------------------------------------
@st.cache_data(show_spinner="Loading sales data…")
def load_data() -> pd.DataFrame:
    df = query("SELECT * FROM sales_cleaned")
    df['order_date'] = pd.to_datetime(df['order_date'])
    df['year'] = df['year'].astype(int)
    return df


df_all = load_data()

# ---------------------------------------------------------------------------
# Sidebar — filters
# ---------------------------------------------------------------------------
st.sidebar.title("Filters")

all_years = sorted(df_all['year'].unique().tolist())
selected_years = st.sidebar.multiselect(
    "Year",
    options=all_years,
    default=all_years,
)

all_markets = sorted(df_all['markets_name'].unique().tolist())
selected_markets = st.sidebar.multiselect(
    "Market",
    options=all_markets,
    default=all_markets,
)

all_zones = sorted(df_all['zone'].unique().tolist())
selected_zones = st.sidebar.multiselect(
    "Zone",
    options=all_zones,
    default=all_zones,
)

st.sidebar.markdown("---")
st.sidebar.caption(
    "All revenue figures are in **INR**.  \n"
    "USD transactions converted at ₹83/\\$."
)

# Apply filters
df = df_all[
    df_all['year'].isin(selected_years) &
    df_all['markets_name'].isin(selected_markets) &
    df_all['zone'].isin(selected_zones)
].copy()

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
st.title("📊 AtliQ Hardware — Sales Insights")
st.caption(
    f"Showing **{len(df):,}** transactions · "
    f"Years: {', '.join(map(str, selected_years))} · "
    f"Markets: {len(selected_markets)} selected"
)

# ---------------------------------------------------------------------------
# KPI tiles — top row
# ---------------------------------------------------------------------------
total_rev   = df['sales_amount_inr'].sum()
total_units = df['sales_qty'].sum()
total_txns  = len(df)
avg_txn     = df['sales_amount_inr'].mean() if total_txns > 0 else 0

k1, k2, k3, k4 = st.columns(4)
k1.metric("Total Revenue (INR)", f"₹{total_rev/1e7:.2f} Cr")
k2.metric("Units Sold",          f"{total_units:,}")
k3.metric("Transactions",        f"{total_txns:,}")
k4.metric("Avg Transaction",     f"₹{avg_txn:,.0f}")

st.markdown("---")

# ---------------------------------------------------------------------------
# Row 1 — Revenue Trend (full width)
# ---------------------------------------------------------------------------
st.subheader("Revenue Trend")

MONTH_ORDER = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
]

monthly = (
    df.groupby(['year', 'month_name'], as_index=False)
      .agg(revenue_inr=('sales_amount_inr', 'sum'))
)
monthly['month_num'] = monthly['month_name'].apply(
    lambda m: MONTH_ORDER.index(m) + 1 if m in MONTH_ORDER else 0
)
monthly = monthly.sort_values(['year', 'month_num'])
monthly['period'] = (
    monthly['year'].astype(str) + '-'
    + monthly['month_num'].astype(str).str.zfill(2)
)

# Rolling average overlay on the aggregated series
monthly_ts = (
    df.groupby(df['order_date'].dt.to_period('M'))
      .agg(revenue_inr=('sales_amount_inr', 'sum'))
      .reset_index()
)
monthly_ts['order_date'] = monthly_ts['order_date'].dt.to_timestamp()
monthly_ts = monthly_ts.sort_values('order_date')
monthly_ts['rolling_3m'] = monthly_ts['revenue_inr'].rolling(3, min_periods=1).mean()

fig_trend = go.Figure()
fig_trend.add_trace(go.Bar(
    x=monthly_ts['order_date'], y=monthly_ts['revenue_inr'],
    name='Monthly Revenue', marker_color='#4C8BF5', opacity=0.7
))
fig_trend.add_trace(go.Scatter(
    x=monthly_ts['order_date'], y=monthly_ts['rolling_3m'],
    name='3-Month Rolling Avg',
    line=dict(color='#FF6B35', width=2.5)
))
fig_trend.update_layout(
    xaxis_title='Month', yaxis_title='Revenue (INR)',
    legend=dict(orientation='h', yanchor='bottom', y=1.02, xanchor='right', x=1),
    height=350, margin=dict(t=10)
)
st.plotly_chart(fig_trend, use_container_width=True)

st.markdown("---")

# ---------------------------------------------------------------------------
# Row 2 — Top 5 Customers | Top 5 Products
# ---------------------------------------------------------------------------
col_left, col_right = st.columns(2)

# --- Top 5 Customers ---
with col_left:
    st.subheader("Top 5 Customers")

    top_cust = (
        df.groupby(['customer_name', 'customer_type'], as_index=False)
          .agg(revenue_inr=('sales_amount_inr', 'sum'))
          .sort_values('revenue_inr', ascending=False)
          .head(5)
    )
    top_cust['label'] = top_cust['revenue_inr'].apply(lambda v: f'₹{v/1e7:.2f}Cr')

    fig_cust = px.bar(
        top_cust,
        x='revenue_inr', y='customer_name',
        orientation='h',
        color='customer_type',
        text='label',
        color_discrete_map={
            'Brick & Mortar': '#4C8BF5',
            'E-Commerce':     '#FF6B35',
        },
        labels={'revenue_inr': 'Revenue (INR)', 'customer_name': ''},
    )
    fig_cust.update_traces(textposition='outside')
    fig_cust.update_layout(
        yaxis=dict(autorange='reversed'),
        legend_title='Channel',
        height=320, margin=dict(t=10)
    )
    st.plotly_chart(fig_cust, use_container_width=True)

# --- Top 5 Products ---
with col_right:
    st.subheader("Top 5 Products")

    top_prod = (
        df.groupby(['product_code', 'product_type'], as_index=False)
          .agg(revenue_inr=('sales_amount_inr', 'sum'))
          .sort_values('revenue_inr', ascending=False)
          .head(5)
    )
    top_prod['label'] = top_prod['revenue_inr'].apply(lambda v: f'₹{v/1e7:.2f}Cr')

    fig_prod = px.bar(
        top_prod,
        x='revenue_inr', y='product_code',
        orientation='h',
        color='product_type',
        text='label',
        labels={'revenue_inr': 'Revenue (INR)', 'product_code': ''},
    )
    fig_prod.update_traces(textposition='outside')
    fig_prod.update_layout(
        yaxis=dict(autorange='reversed'),
        legend_title='Type',
        height=320, margin=dict(t=10)
    )
    st.plotly_chart(fig_prod, use_container_width=True)

st.markdown("---")

# ---------------------------------------------------------------------------
# Row 3 — Market Performance | Channel Mix
# ---------------------------------------------------------------------------
col_mkt, col_chan = st.columns(2)

# --- Market Performance ---
with col_mkt:
    st.subheader("Market Performance")

    mkt_rev = (
        df.groupby(['markets_name', 'zone'], as_index=False)
          .agg(revenue_inr=('sales_amount_inr', 'sum'))
          .sort_values('revenue_inr', ascending=False)
    )

    ZONE_COLORS = {
        'North':         '#4C8BF5',
        'South':         '#34A853',
        'Central':       '#FBBC05',
        'International': '#EA4335',
    }

    fig_mkt = px.bar(
        mkt_rev,
        x='revenue_inr', y='markets_name',
        orientation='h',
        color='zone',
        color_discrete_map=ZONE_COLORS,
        labels={'revenue_inr': 'Revenue (INR)', 'markets_name': ''},
    )
    fig_mkt.update_layout(
        yaxis=dict(autorange='reversed'),
        legend_title='Zone',
        height=420, margin=dict(t=10)
    )
    st.plotly_chart(fig_mkt, use_container_width=True)

# --- Channel Mix over time ---
with col_chan:
    st.subheader("Channel Mix by Year")

    channel = (
        df.groupby(['year', 'customer_type'], as_index=False)
          .agg(revenue_inr=('sales_amount_inr', 'sum'))
    )
    channel['pct'] = (
        channel['revenue_inr']
        / channel.groupby('year')['revenue_inr'].transform('sum')
        * 100
    ).round(1)

    fig_chan = px.bar(
        channel,
        x='year', y='pct',
        color='customer_type',
        barmode='stack',
        text=channel['pct'].apply(lambda v: f'{v:.0f}%'),
        color_discrete_map={
            'Brick & Mortar': '#4C8BF5',
            'E-Commerce':     '#FF6B35',
        },
        labels={'pct': 'Share (%)', 'year': 'Year', 'customer_type': 'Channel'},
    )
    fig_chan.update_traces(textposition='inside', textfont_size=12)
    fig_chan.update_layout(
        yaxis=dict(range=[0, 105], title='Share (%)'),
        legend_title='Channel',
        height=420, margin=dict(t=10)
    )
    st.plotly_chart(fig_chan, use_container_width=True)

st.markdown("---")

# ---------------------------------------------------------------------------
# Row 4 — YoY Growth (full width)
# ---------------------------------------------------------------------------
st.subheader("Year-over-Year Revenue Growth")

annual = (
    df.groupby('year', as_index=False)
      .agg(revenue_inr=('sales_amount_inr', 'sum'))
      .sort_values('year')
)
annual['yoy_pct'] = annual['revenue_inr'].pct_change() * 100

yoy = annual.dropna(subset=['yoy_pct']).copy()
yoy['color'] = yoy['yoy_pct'].apply(lambda v: 'positive' if v >= 0 else 'negative')
yoy['label'] = yoy['yoy_pct'].apply(lambda v: f'{v:+.1f}%')

fig_yoy = px.bar(
    yoy, x='year', y='yoy_pct',
    color='color',
    text='label',
    color_discrete_map={'positive': '#34A853', 'negative': '#EA4335'},
    labels={'yoy_pct': 'YoY Growth (%)', 'year': 'Year'},
)
fig_yoy.add_hline(y=0, line_dash='dash', line_color='grey')
fig_yoy.update_traces(textposition='outside')
fig_yoy.update_layout(
    showlegend=False,
    height=320, margin=dict(t=10)
)
st.plotly_chart(fig_yoy, use_container_width=True)

# ---------------------------------------------------------------------------
# Footer
# ---------------------------------------------------------------------------
st.markdown("---")
st.caption(
    "AtliQ Hardware Sales Insights · Data: Codebasics · "
    "Built with Streamlit + Plotly · "
    "USD → INR at ₹83/\\$"
)
