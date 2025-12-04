-- =====================================================
-- NORTHWIND DATA WAREHOUSE (DWH) - SCHEMA CREATION
-- =====================================================

-- Buat database baru
CREATE DATABASE IF NOT EXISTS northwind_dwh;
USE northwind_dwh;

-- Set SQL mode dan checks
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- =====================================================
-- TABEL DIMENSI
-- =====================================================

-- -----------------------------------------------------
-- Tabel Dim_Customer
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dim_customer`;
CREATE TABLE `dim_customer` (
  `CustomerKey` INT(11) NOT NULL AUTO_INCREMENT,
  `CustomerID_OLTP` INT(11) NOT NULL,
  `CompanyName` VARCHAR(50) NULL DEFAULT NULL,
  `City` VARCHAR(50) NULL DEFAULT NULL,
  `Country` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`CustomerKey`),
  UNIQUE INDEX `CustomerID_OLTP_UNIQUE` (`CustomerID_OLTP` ASC),
  INDEX `idx_city` (`City` ASC),
  INDEX `idx_country` (`Country` ASC)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COMMENT = 'Dimensi Pelanggan';

-- -----------------------------------------------------
-- Tabel Dim_Product
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dim_product`;
CREATE TABLE `dim_product` (
  `ProductKey` INT(11) NOT NULL AUTO_INCREMENT,
  `ProductID_OLTP` INT(11) NOT NULL,
  `ProductName` VARCHAR(50) NULL DEFAULT NULL,
  `CategoryName` VARCHAR(50) NULL DEFAULT NULL,
  `SupplierName` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`ProductKey`),
  UNIQUE INDEX `ProductID_OLTP_UNIQUE` (`ProductID_OLTP` ASC),
  INDEX `idx_category` (`CategoryName` ASC),
  INDEX `idx_supplier` (`SupplierName` ASC)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COMMENT = 'Dimensi Produk (Denormalized)';

-- -----------------------------------------------------
-- Tabel Dim_Employee
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dim_employee`;
CREATE TABLE `dim_employee` (
  `EmployeeKey` INT(11) NOT NULL AUTO_INCREMENT,
  `EmployeeID_OLTP` INT(11) NOT NULL,
  `FullName` VARCHAR(100) NULL DEFAULT NULL,
  `Title` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`EmployeeKey`),
  UNIQUE INDEX `EmployeeID_OLTP_UNIQUE` (`EmployeeID_OLTP` ASC),
  INDEX `idx_title` (`Title` ASC)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COMMENT = 'Dimensi Karyawan';

-- -----------------------------------------------------
-- Tabel Dim_Time
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dim_time`;
CREATE TABLE `dim_time` (
  `DateKey` INT(11) NOT NULL COMMENT 'Format: YYYYMMDD (ex: 20231025)',
  `Date` DATE NOT NULL,
  `Month` TINYINT(2) NOT NULL COMMENT '1-12',
  `Quarter` TINYINT(1) NOT NULL COMMENT '1-4',
  `Year` SMALLINT(4) NOT NULL,
  `DayOfWeek` TINYINT(1) NOT NULL COMMENT '1=Monday, 7=Sunday',
  `MonthName` VARCHAR(10) NULL DEFAULT NULL,
  `QuarterName` VARCHAR(2) NULL DEFAULT NULL COMMENT 'Q1, Q2, Q3, Q4',
  `DayName` VARCHAR(10) NULL DEFAULT NULL,
  PRIMARY KEY (`DateKey`),
  UNIQUE INDEX `Date_UNIQUE` (`Date` ASC),
  INDEX `idx_year` (`Year` ASC),
  INDEX `idx_quarter` (`Quarter` ASC),
  INDEX `idx_month` (`Month` ASC)
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COMMENT = 'Dimensi Waktu';

-- =====================================================
-- TABEL FAKTA
-- =====================================================

-- -----------------------------------------------------
-- Tabel Fact_Sales
-- -----------------------------------------------------
DROP TABLE IF EXISTS `fact_sales`;
CREATE TABLE `fact_sales` (
  `SalesKey` INT(11) NOT NULL AUTO_INCREMENT,
  `DateKey` INT(11) NOT NULL COMMENT 'FK to Dim_Time (Format: YYYYMMDD)',
  `CustomerKey` INT(11) NOT NULL COMMENT 'FK to Dim_Customer',
  `ProductKey` INT(11) NOT NULL COMMENT 'FK to Dim_Product',
  `EmployeeKey` INT(11) NOT NULL COMMENT 'FK to Dim_Employee',
  `OrderID` INT(11) NOT NULL COMMENT 'Degenerate Dimension - No Invoice',
  `Quantity` DECIMAL(18,4) NOT NULL DEFAULT 0.0000,
  `Unit_Price` DECIMAL(19,4) NOT NULL DEFAULT 0.0000,
  `Total_Sales` DECIMAL(19,4) NOT NULL DEFAULT 0.0000 COMMENT 'Quantity * Unit_Price',
  PRIMARY KEY (`SalesKey`),
  INDEX `fk_fact_sales_dim_time` (`DateKey` ASC),
  INDEX `fk_fact_sales_dim_customer` (`CustomerKey` ASC),
  INDEX `fk_fact_sales_dim_product` (`ProductKey` ASC),
  INDEX `fk_fact_sales_dim_employee` (`EmployeeKey` ASC),
  INDEX `idx_orderid` (`OrderID` ASC),
  INDEX `idx_date_customer` (`DateKey` ASC, `CustomerKey` ASC),
  INDEX `idx_date_product` (`DateKey` ASC, `ProductKey` ASC),
  CONSTRAINT `fk_fact_sales_dim_time`
    FOREIGN KEY (`DateKey`)
    REFERENCES `dim_time` (`DateKey`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_sales_dim_customer`
    FOREIGN KEY (`CustomerKey`)
    REFERENCES `dim_customer` (`CustomerKey`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_sales_dim_product`
    FOREIGN KEY (`ProductKey`)
    REFERENCES `dim_product` (`ProductKey`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_fact_sales_dim_employee`
    FOREIGN KEY (`EmployeeKey`)
    REFERENCES `dim_employee` (`EmployeeKey`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COMMENT = 'Tabel Fakta Penjualan';

-- =====================================================
-- RESTORE SETTINGS
-- =====================================================
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- =====================================================
-- VIEWS UNTUK ANALISIS (OPTIONAL)
-- =====================================================

-- View: Sales Summary by Product
CREATE OR REPLACE VIEW vw_sales_by_product AS
SELECT 
    p.ProductName,
    p.CategoryName,
    SUM(f.Quantity) AS Total_Quantity,
    SUM(f.Total_Sales) AS Total_Revenue,
    COUNT(DISTINCT f.OrderID) AS Total_Orders
FROM fact_sales f
INNER JOIN dim_product p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductKey, p.ProductName, p.CategoryName;

-- View: Sales Summary by Customer
CREATE OR REPLACE VIEW vw_sales_by_customer AS
SELECT 
    c.CompanyName,
    c.City,
    c.Country,
    SUM(f.Quantity) AS Total_Quantity,
    SUM(f.Total_Sales) AS Total_Revenue,
    COUNT(DISTINCT f.OrderID) AS Total_Orders
FROM fact_sales f
INNER JOIN dim_customer c ON f.CustomerKey = c.CustomerKey
GROUP BY c.CustomerKey, c.CompanyName, c.City, c.Country;

-- View: Sales Summary by Time
CREATE OR REPLACE VIEW vw_sales_by_time AS
SELECT 
    t.Year,
    t.Quarter,
    t.MonthName,
    SUM(f.Quantity) AS Total_Quantity,
    SUM(f.Total_Sales) AS Total_Revenue,
    COUNT(DISTINCT f.OrderID) AS Total_Orders
FROM fact_sales f
INNER JOIN dim_time t ON f.DateKey = t.DateKey
GROUP BY t.Year, t.Quarter, t.Month, t.MonthName
ORDER BY t.Year, t.Month;

-- View: Sales Summary by Employee
CREATE OR REPLACE VIEW vw_sales_by_employee AS
SELECT 
    e.FullName,
    e.Title,
    SUM(f.Quantity) AS Total_Quantity,
    SUM(f.Total_Sales) AS Total_Revenue,
    COUNT(DISTINCT f.OrderID) AS Total_Orders
FROM fact_sales f
INNER JOIN dim_employee e ON f.EmployeeKey = e.EmployeeKey
GROUP BY e.EmployeeKey, e.FullName, e.Title;

-- =====================================================
-- SELESAI
-- =====================================================