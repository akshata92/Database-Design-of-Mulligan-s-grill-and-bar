#--------------------------------------------	VIEWS	-----------------------------------------------------------------------------------------------------------
#VIEW1: Calculate Datewise Total Purchase in Ounces
CREATE VIEW Total_Purchase_In_Ounces AS
	SELECT DATE_FORMAT(Drink_Purchase.Date,'%y-%m-%d') AS Purchase_Date, Drink_Purchase_Details.Drink_ID AS Drink_ID,
		   SUM((SELECT Drink_Units.Quantity_In_Ounces FROM Drink_Units WHERE Drink_Units.Unit_ID = Drink_Purchase_Details.Unit_ID) * Drink_Purchase_Details.Quantity) AS Purchase_Quantity
	FROM Drink_Purchase_Details 
    JOIN Drink_Purchase ON Drink_Purchase.Drink_Purchase_ID = Drink_Purchase_Details.Drink_Purchase_ID
    GROUP BY DATE_FORMAT(Drink_Purchase.Date,'%y-%m-%d'), Drink_Purchase_Details.Drink_ID;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
#VIEW2: Calculating Datewise Total Sale/Use in Ounces
CREATE VIEW Total_Sale_In_Ounces AS
	SELECT A.Sale_Date, A.Drink_ID, SUM(A.Total) AS 'Sale_Quantity' FROM
    (
		SELECT DATE_FORMAT(Tab.Tab_Open_DateTime,'%y-%m-%d') as Sale_Date, Tab_Drinks.Drink_ID, 
		SUM((SELECT Drink_Units.Quantity_In_Ounces FROM Drink_Units WHERE Drink_Units.Unit_ID = Tab_Drinks.Drink_Unit_ID )* Tab_Drinks.Quantity) AS Total
		FROM Tab_Drinks
		JOIN Tab ON Tab.Tab_ID = Tab_Drinks.Tab_ID
		WHERE Tab_Drinks.Tab_Drinks_ID NOT IN (SELECT Tab_Drinks_Components.Tab_Drinks_ID FROM Tab_Drinks_Components)
		GROUP BY DATE_FORMAT(Tab.Tab_Open_DateTime,'%y-%m-%d'), Tab_Drinks.Drink_ID
		UNION
		SELECT DATE_FORMAT(Tab.Tab_Open_DateTime,'%y-%m-%d'), Tab_Drinks_Components.Component_ID AS Drink_ID, 
        SUM(Tab_Drinks_Components.Quantity) AS Total
		FROM Tab_Drinks_Components
		JOIN Tab_Drinks ON Tab_Drinks.Tab_Drinks_ID = Tab_Drinks_Components.Tab_Drinks_ID
		JOIN Tab ON Tab.Tab_ID = Tab_Drinks.Tab_ID 
		GROUP BY DATE_FORMAT(Tab.Tab_Open_DateTime,'%y-%m-%d'), Tab_Drinks_Components.Component_ID) A
	GROUP BY A.Sale_Date, A.Drink_ID;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

# VIEW3: Display Tab drink details (Drink Name, Quantity, Unit) by creating a View.
CREATE VIEW Tab_view AS
SELECT Tab_ID, Drink_Name, Unit_Name, Unit_Price,Quantity, Quantity * Unit_Price as Total from Tab_Drinks 
JOIN Drink on Drink.Drink_ID = Tab_Drinks.Drink_ID
JOIN Drink_Units on Drink_Units.Unit_ID = Tab_Drinks.Drink_Unit_ID;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

#VIEW4: Display date wise Tab details
CREATE VIEW Tab_Sales AS
SELECT DATE_FORMAT(Tab.Tab_Open_DateTime,'%y-%m-%d') AS Sale_Date, Tab_Drinks.Drink_ID, Tab_Drinks.Drink_Unit_ID, SUM(Quantity) as Total 
FROM Tab_Drinks 
JOIN Tab ON Tab.Tab_ID = Tab_Drinks.Tab_ID 
GROUP BY DATE_FORMAT(Tab.Tab_Open_DateTIme,'%y-%m-%d'),Tab_Drinks.Drink_ID, Tab_Drinks.Drink_Unit_ID;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------
#******************************************************************************************************************************************************************
#------------------------------------------------------------------------------------------------------------------------------------------------------------------


#-----------------------------------------------	QUERIES		---------------------------------------------------------------------------------------------------

#Query1:Display the most sold alcohol on a selected date along with the quantity and unit at which it is sold.
SET @SelectedDate = '16-04-30';
SELECT Tab_Sales.Drink_ID AS 'Drink ID' , Drink.Drink_Name AS 'Drink Name', Tab_Sales.Total AS 'Total Quantity', Drink_Units.Unit_Name as 'Unit Name' 
FROM Tab_Sales
JOIN Drink ON Drink.Drink_ID = Tab_Sales.Drink_ID
JOIN Drink_Units ON Drink_Units.Unit_ID = Tab_Sales.Drink_Unit_ID
WHERE Sale_Date = @SelectedDate
AND Total = (Select MAX(Total) FROM Tab_Sales where Sale_Date = @SelectedDate);

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------

#Query2: Display a list of all cocktails whose components have a particular drink category. [Eg 'Vodka']
SET @drinkCategory = 'Vodka';
SELECT Drink_ID AS 'Drink ID', Drink_Name AS 'Drink Name' 
FROM drink 
JOIN cocktail_component ON drink.Drink_ID=cocktail_component.Cocktail_ID
WHERE Drink_Category_ID IN (SELECT Drink_Category_ID FROM drink_category WHERE Drink_Category_Name= 'Cocktail')
AND cocktail_component.Component_ID IN (SELECT drink_category.Drink_Category_ID FROM drink_category WHERE drink_category.Drink_Category_Name=@drinkCategory);

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Query 3: Display a list of all drinks purchased between two dates along with the quantity purchased.
SET @StartDate = '16-05-01';
SET @EndDate = '16-05-02';
(SELECT Drink.Drink_Name AS 'Drink Name', SUM(Quantity) AS 'Total Quantity Purchased' , Drink_Units.Unit_Name AS 'Unit Name' 
FROM Drink_Purchase_Details
JOIN Drink_Purchase ON Drink_Purchase.Drink_Purchase_ID =  Drink_Purchase_Details.Drink_Purchase_ID
JOIN Drink ON Drink_Purchase_Details.Drink_ID = Drink.Drink_ID
JOIN Drink_Units ON Drink_Purchase_Details.Unit_ID = Drink_Units.Unit_ID
WHERE DATE_FORMAT(Drink_Purchase.Date,'%y-%m-%d') BETWEEN @StartDate AND @EndDate
GROUP BY Drink.Drink_Name, Drink_Units.Unit_Name
ORDER BY Drink.Drink_Name, Drink_Units.Unit_Name);

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Query4: Calculate total price for Tab_view with taxes for any displayed Tab ID.
SET @Tab_ID = 3;
SELECT tab_id as 'Tab ID', SUM(Quantity*Total)+ 0.3*SUM(Quantity*Total) AS 'Total Amount' 
FROM tab_view 
WHERE Tab_ID=@Tab_ID;

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------

#Query5: Display revenue generated for all the Drink Categories on a particular day.
SET @RevenueDate = '16-05-01';
SELECT drink_category.Drink_Category_Name AS 'Drink Category Name', SUM(Quantity *Unit_Price) AS Revenue 
FROM tab_drinks
JOIN Drink ON tab_drinks.Drink_ID = drink.Drink_ID
JOIN Tab ON Tab_drinks.Tab_ID = Tab.Tab_ID 
JOIN drink_category ON drink_category.Drink_Category_ID = drink.Drink_Category_ID
WHERE DATE_FORMAT(Tab.Tab_Open_DateTIme,'%y-%m-%d') = @RevenueDate
GROUP BY drink_category.Drink_Category_Name ;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Query6 Display all the units and prices in which a particular alcohol is sold. Eg: Miller Lite
SET @drinkName = 'Miller Lite';
SELECT drink_units.Unit_ID AS 'Unit ID', drink_units.Unit_Name AS 'Unit Name', Unit_Price AS 'Unit Price'
FROM drink_units
JOIN drink_details ON drink_details.Unit_ID = drink_units.Unit_ID
WHERE drink_details.Drink_ID IN (SELECT drink.Drink_ID FROM Drink WHERE drink.Drink_Name=@drinkName);

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Query7: Display Stock Report for a particular Date.  
SET @ReportDate = '16-04-30';
SET @ReportDateMinus1 = '16-04-29';
SELECT Drink.Drink_ID, 
	   Drink.Drink_Name,
	   I1.Actual_Closing_Balance as 'Opening Balance', 
       IFNULL(total_purchase_in_ounces.Purchase_Quantity,0) AS 'Total Purchase', 
       IFNULL(total_sale_in_ounces.Sale_Quantity,0) AS 'Total Sale',
       I1.Actual_Closing_Balance + IFNULL(total_purchase_in_ounces.Purchase_Quantity,0) - IFNULL(total_sale_in_ounces.Sale_Quantity,0) 'Theoritical Closing Balance',
       I2.Actual_Closing_Balance AS 'Actual Closing Balance',
       I2.Actual_Closing_Balance- (I1.Actual_Closing_Balance + IFNULL(total_purchase_in_ounces.Purchase_Quantity,0) - IFNULL(total_sale_in_ounces.Sale_Quantity,0)) AS 'Difference'
FROM Drink
LEFT JOIN Inventory I1 ON I1.Drink_ID = Drink.Drink_ID AND DATE_FORMAT(I1.Date,'%y-%m-%d') = @ReportDateMinus1
LEFT JOIN Inventory I2 ON I2.Drink_ID = Drink.Drink_ID AND DATE_FORMAT(I2.Date,'%y-%m-%d') = @ReportDate
LEFT JOIN total_purchase_in_ounces ON total_purchase_in_ounces.Drink_ID = Drink.Drink_ID AND  total_purchase_in_ounces.Purchase_Date = @ReportDate
LEFT JOIN total_sale_in_ounces ON total_sale_in_ounces.Drink_ID = Drink.Drink_ID AND  total_sale_in_ounces.Sale_Date = @ReportDate
WHERE Drink.Drink_Category_ID != 15 
AND (I1.Actual_Closing_Balance != 0 OR IFNULL(total_purchase_in_ounces.Purchase_Quantity,0) !=0 OR IFNULL(total_sale_in_ounces.Sale_Quantity,0)!=0 )
ORDER BY Drink.Drink_ID;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

#Query8:Display the list of drinks sold during happy hour.
SELECT drink_details.drink_id as 'Drink ID', drink.Drink_Name as 'Drink Name', drink_units.Unit_Name as 'Unit Name'
FROM drink_details
JOIN drink ON drink.drink_id = drink_details.Drink_ID
JOIN drink_Units ON Drink_Units.Unit_ID = drink_details.Unit_ID
WHERE drink_details.Happy_Hour_Availability = 1;
#-----------------------------------------------------------------------------------------------------------------------------------------------------------

