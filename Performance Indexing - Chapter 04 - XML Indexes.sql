--listing 4.1 


--listing 4.2
CREATE XML SCHEMA COLLECTION CheckoutCouponSchema AS '
<schema xmlns="http://www.w3.org/2001/XMLSchema">
  <element name="CheckoutItem">
    <complexType>
      <sequence>
        <element name="TotalSales" minOccurs="0">
          <complexType>
            <sequence>
              <element name="Product" minOccurs="1" maxOccurs="unbounded">
                <complexType>
                 <sequence>
            <element name="ItemSale" minOccurs="1" maxOccurs="unbounded">
            <complexType>
             <sequence>
              <element name="NetPrice" type="string" />
              <element name="CouponPrice" type="string" />
             </sequence>
            </complexType>
          </element>
         </sequence>
         <attribute name="ProdID" type="string" use="required" />
         <attribute name="ProdName" type="string" use="required" />
               </complexType>
              </element>
            </sequence>
          </complexType>
        </element>
      </sequence>
      <attribute name="date" type="string" use="required" />
    </complexType>
  </element>
</schema>'
GO


--listing 4.3
CREATE TABLE dbo.PointOfSale (
     PointOfSaleID BIGINT IDENTITY(1, 1)
                          NOT NULL,
     XMLValue XML(CONTENT dbo.CheckoutCouponSchema) NULL,
     PRIMARY KEY CLUSTERED (PointOfSaleID ASC)
    );

--listing 4.4
DECLARE @XML XML;
SET @XML = '<CheckoutItem date="2/2/2010">
  <TotalSales>
    <Product ProdID="937" ProdName="Wonder bread">
      <ItemSale>
        <NetPrice>1.32</NetPrice>
        <CouponPrice>.97</CouponPrice>
      </ItemSale>
    </Product>
    <Product ProdID="468" ProdName="JIFF Peanut Butter">
      <ItemSale>
        <NetPrice>2.99</NetPrice>
        <CouponPrice>.40</CouponPrice>
      </ItemSale>
    </Product>
  </TotalSales>
</CheckoutItem>';

INSERT  INTO dbo.PointOfSale
VALUES  (@XML);


--listing 4.5
SELECT  pos.XMLValue.query('/CheckoutItem/TotalSales') AS Results
FROM    dbo.PointOfSale AS pos;



--listing 4.6
CREATE PRIMARY XML INDEX IDX_PRIMARY ON dbo.PointOfSale (XMLValue);

--DROP INDEX IDX_PRIMARY ON dbo.PointOfSale;



--Listing 4.7
CREATE XML INDEX IDX_SEC_PATHS ON dbo.PointOfSale (XMLValue)
USING XML INDEX IDX_PRIMARY
FOR VALUE;


--listing 4.8
SELECT  index_type_desc,
        fragment_count,
        avg_page_space_used_in_percent,
        record_count
FROM    sys.dm_db_index_physical_stats(DB_ID(N'AdventureWorks2014'),
                                       OBJECT_ID(N'dbo.PointOfSale'), NULL,
                                       NULL, 'DETAILED');


--listing 4.9
SELECT  pos.XMLValue.value('(/CheckoutItem/TotalSales/Product/ItemSale/NetPrice)[1
                           ]',
                           'varchar(max)') AS [Net Price],
        pos.XMLValue.value('(/CheckoutItem/TotalSales/Product/ItemSale/CouponPrice)[1]',
                           'varchar(max)') AS [Coupon Savings]
FROM    dbo.PointOfSale AS pos
WHERE   pos.XMLValue.exist('//TotalSales/Product/@ProdID[.=''468'']') = 1;


--listing 4.10
CREATE PRIMARY XML INDEX IDX_PRIMARY ON dbo.PointOfSale (XMLValue);


--listing 4.11
SELECT  pos.XMLValue
FROM    dbo.PointOfSale AS pos
WHERE   pos.XMLValue.exist('(CheckoutItem[@date="2/2/2010"])[1]') = 1;



--listing 4.12
CREATE XML INDEX IDX_SEC_PATH ON dbo.PointOfSale (XMLValue)
USING XML INDEX IDX_PRIMARY
FOR PATH;

--DROP INDEX idx_sec_path ON dbo.PointOfSale;

--listing 4.13
CREATE XML INDEX IDX_SEC_VALUE ON dbo.PointOfSale (XMLValue)
USING XML INDEX IDX_PRIMARY
FOR VALUE;

--DROP INDEX idx_sec_value ON dbo.PointOfSale;


--listing 4.X
DECLARE @PlanHandle VARBINARY(64)

SELECT @PlanHandle = deqs.plan_handle 
FROM sys.dm_exec_query_stats AS deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
WHERE dest.text LIKE 'SELECT  pos.XMLValue%'

DBCC FREEPROCCACHE(@PlanHandle);



--listing 4.14
CREATE XML INDEX IDX_SEC_PROP ON dbo.PointOfSale (XMLValue)
USING XML INDEX IDX_PRIMARY
FOR PROPERTY;

--DROP INDEX IDX_SEC_PROP ON dbo.PointOfSale;


--Listing 4.15
DROP INDEX IDX_SEC_PROP ON dbo.PointOfSale;
DROP INDEX idx_sec_value ON dbo.PointOfSale;



--listing 4.16
CREATE SELECTIVE XML INDEX IDX_SEL_XML
ON dbo.PointOfSale (XMLValue)
FOR
(CouponPrice = 'CheckoutItem/TotalSales/Product/ItemSale/CouponPrice');


DROP INDEX IDX_SEL_XML ON dbo.PointOfSale


--listing 4.17
SELECT  pos.XMLValue
FROM    dbo.PointOfSale AS pos
WHERE   pos.XMLValue.exist('(CheckoutItem/TotalSales/Product
						/ItemSale/CouponPrice[.>".5"])') = 1;




