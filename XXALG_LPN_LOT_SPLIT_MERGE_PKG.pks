CREATE OR REPLACE PACKAGE xxalg_lpn_lot_split_merge_pkg
AS
/* $Header: $*/
/*#
* This interface to do Move+Complete+pack Transaction.
* @rep:scope public
* @rep:product WIP
* @rep:displayname xxalg_lpn_lot_split_merge_pkg
* @rep:lifecycle active
* @rep:compatibility S
* @rep:category
*/
--//=============================================================================
--//
--// Object Name     :: xxalg_lpn_lot_split_merge_pkg
--//
--// Object Type     :: Package Specification
--//
--// Object Description :: To Split and Merge of the LOT and LPN
--//
--//
--// Version Control
--//===========================================================================
--// Vers       Author             Date           Descriptionss
--//---------------------------------------------------------------------------
--//1.0     Subramanian B         01-Feb-2021        Initial Build
--//===========================================================================
   TYPE lpn_split_rec_type IS RECORD (
      mobiletransactionid     VARCHAR2 (30),
      inventoryorgid          NUMBER,      
      sourcelpnid             NUMBER, 
      destlpnid               NUMBER,
	  inventoryitemid         NUMBER,
	  uomcode                 VARCHAR2 (100),
	  quantity                NUMBER,
	  lotnumber  varchar2(400),
	  SerialNumber varchar2(400),
      transactiondate         VARCHAR2 (50),      
      userid                  NUMBER,
      responsibilityid        NUMBER
   );

   TYPE lpn_merge_rec_type IS RECORD (
      mobiletransactionid      VARCHAR2 (30),
      inventoryorgid           NUMBER,
      sourcelpnid              NUMBER,
      destlpnid                NUMBER,
      transactiondate          VARCHAR2 (50),
      userid                   NUMBER,
      responsibilityid         NUMBER
   );

   TYPE lot_split_rec_type IS RECORD (
      mobiletransactionid      VARCHAR2 (30),
      inventoryorgid           NUMBER,
	  sourcelotnumber          VARCHAR2 (80), 
      inventoryitemid          NUMBER,
      sourcelpnid              NUMBER,
      sourcesubinventorycode   VARCHAR2 (50),
      sourcelocator            VARCHAR2 (100),      
      uomcode                  VARCHAR2 (100),
      destlotnumber            VARCHAR2 (80),
	  destlpnid                NUMBER,
      destsubinventorycode     VARCHAR2 (50),
      destlocator              VARCHAR2 (100),
	  quantity                 NUMBER,      
      transactiondate          VARCHAR2 (50),      
      userid                   NUMBER,
      responsibilityid         NUMBER
   );

   TYPE lot_merge_rec_type IS RECORD (
      mobiletransactionid      VARCHAR2 (30),
      inventoryorgid           NUMBER,
	  sourcelotnumber          VARCHAR2 (80), 
      inventoryitemid          NUMBER,
      sourcelpnid              NUMBER,
      sourcesubinventorycode   VARCHAR2 (50),
      sourcelocator            VARCHAR2 (100),      
      uomcode                  VARCHAR2 (100),
      destlotnumber            VARCHAR2 (80),
	  destlpnid                NUMBER,
      destsubinventorycode     VARCHAR2 (50),
      destlocator              VARCHAR2 (100),
	  quantity                 NUMBER,      
      transactiondate          VARCHAR2 (50),      
      userid                   NUMBER,
      responsibilityid         NUMBER
   );


/*#
* Create Move Transaction of WIP Job
* @param p_clob CLOB
* @param x_return_msg CLOB
* @rep:scope public
* @rep:lifecycle active
* @rep:displayname Create Move Transaction of WIP Job
*/
   PROCEDURE lpn_split_main (p_clob CLOB, x_return_msg OUT CLOB);

   PROCEDURE lpn_merge_main (p_clob CLOB, x_return_msg OUT CLOB);

   PROCEDURE lot_split_main (p_clob CLOB, x_return_msg OUT CLOB);

   PROCEDURE lot_merge_main (p_clob CLOB, x_return_msg OUT CLOB);
END xxalg_lpn_lot_split_merge_pkg;
/

