# 🧠 Northwind ETL & Data Warehouse Project  
Kelompok 4 — Business Intelligence / ETL & Data Warehouse

Proyek ini merupakan implementasi proses **ETL (Extract–Transform–Load)** dan **Data Warehouse** menggunakan dataset Northwind. Semua proses meliputi pembuatan Star Schema, implementasi ETL dengan Pentaho, serta visualisasi menggunakan Power BI.

---

## 📁 Struktur Repository

```
│─Kelompok_4_Northwind_ETL/
│
├── README.md <-- Dokumentasi cara install & penjelasan proyek
├── database/
│ ├── northwind_oltp.sql <-- Dump database sumber
│ └── northwind_dwh.sql <-- Dump database hasil (struktur star schema)
│
├── etl_pentaho/
│ ├── dim_product.ktr <-- File transformasi Dimensi Produk
│ ├── dim_customer.ktr <-- File transformasi Dimensi Customer
│ ├── fact_sales.ktr <-- File transformasi Tabel Fakta
│ └── main_job.kjb <-- (Opsional) Job utama untuk menjalankan semua.ktr
│
├── documentation/
│ ├── Laporan_Proyek.pdf <-- Laporan PDF Lengkap
│ └── ERD_Diagram.png <-- Gambar rancangan database
│
└── dashboard/
├── dashboard_report.pbix <-- File Power BI (atau link Looker Studio di README)
└── screenshot_dashboard.png
```

