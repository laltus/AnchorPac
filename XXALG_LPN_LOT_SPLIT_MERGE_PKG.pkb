CREATE OR REPLACE PACKAGE BODY xxalg_lpn_lot_split_merge_pkg
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
--// Vers       Author             Date           Description
--//---------------------------------------------------------------------------
--//1.0     Subramanian B         01-Feb-2021        Initial Build
--//===========================================================================
   g_group_id       NUMBER;
   g_package_name   VARCHAR2 (100) := 'XXALG_LPN_LOT_SPLIT_MERGE_PKG';

   PROCEDURE insert_lpn_merge_gtt (
      p_group_id        IN       NUMBER,
      p_clob            IN       CLOB,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_return_status    VARCHAR2 (10)      := 'S';
      l_err_msg          VARCHAR2 (4000);
      l_wo_index         VARCHAR2 (64);
      l_rec_num          NUMBER             := 0;
      v_stat             VARCHAR2 (1000)
         := q'{
select *
from table(
  pljson_table.json_table(
    :json_str,
    pljson_varray('[*].MobileTransactionId','[*].InventoryOrgId','[*].SourceLpnId','[*].Destlpnid','[*].TransactionDate','[*].UserId','[*].ResponsibilityId'),
    pljson_varray('MOBILETRANSACTIONID','INVENTORYORGID','SOURCELPNID','DESTLPNID','TRANSACTIONDATE','USERID','RESPONSIBILITYID'),
    table_mode=>'nested'
  )
)
}';
      c_cur              sys_refcursor;
      v_rec              lpn_merge_rec_type;
      l_procedure_name   VARCHAR2 (100)     := 'INSERT_LPN_MERGE_GTT';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'Payload',
          p_payload           => 'MOBILETRANSACTIONID|INVENTORYORGID|SOURCELPNID|DESTLPNID|TRANSACTIONDATE|USERID|RESPONSIBILITYID'
         );

      OPEN c_cur FOR v_stat USING p_clob;

      LOOP
         FETCH c_cur
          INTO v_rec;

         EXIT WHEN c_cur%NOTFOUND;
         l_rec_num := l_rec_num + 1;

         INSERT INTO xxalg_lpn_lot_split_merge_gt
                     (record_grp_id, record_num, mobile_transaction_id,
                      inv_org_id, source_lpn_id,
                      dest_lpn_id,
                      transaction_date,
                      responsibility_id, user_id
                     )
              VALUES (p_group_id, l_rec_num, v_rec.mobiletransactionid,
                      v_rec.inventoryorgid, v_rec.sourcelpnid,
                      v_rec.destlpnid,
                      TO_DATE (v_rec.transactiondate,
                               'DD-MON-YYYY hh24:MI:SS'),
                      v_rec.responsibilityid, v_rec.userid
                     );

         xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'Payload',
                                     p_payload           =>    v_rec.mobiletransactionid
                                                            || '|'
                                                            || v_rec.inventoryorgid
                                                            || '|'
                                                            || v_rec.sourcelpnid
                                                            || '|'
                                                            || v_rec.destlpnid
                                                            || '|'
                                                            || v_rec.transactiondate
                                                            || '|'
                                                            || v_rec.userid
                                                            || '|'
                                                            || v_rec.responsibilityid
                                    );
      END LOOP;

      CLOSE c_cur;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg :=
                l_err_msg || 'Exception in INSERT_LPN_MERGE_GTT:-' || SQLERRM;
         x_return_msg := l_err_msg;
         DBMS_OUTPUT.put_line ('Error while INSERT_LPN_MERGE_GTT' || SQLERRM);
         -- clear the data in table type so that none of the record will be processed.
         --p_out_data.DELETE;
         xxprop_common_util_pkg.trace_log
             (p_module            => g_package_name || '.' || l_procedure_name,
              p_message_text      =>    'Error Error while INSERT_LPN_MERGE_GTT-'
                                     || SQLERRM,
              p_payload           => NULL
             );
   END insert_lpn_merge_gtt;

   PROCEDURE insert_lpn_split_gtt (
      p_group_id        IN       NUMBER,
      p_clob            IN       CLOB,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_return_status    VARCHAR2 (10)      := 'S';
      l_err_msg          VARCHAR2 (4000);
      l_wo_index         VARCHAR2 (64);
      l_rec_num          NUMBER             := 0;
      v_stat             VARCHAR2 (1000)
         := q'{
select *
from table(
  pljson_table.json_table(
    :json_str,
    pljson_varray('[*].MobileTransactionId','[*].InventoryOrgId','[*].SourceLpnId','[*].Destlpnid','[*].InventoryItemId','[*].UomCode','[*].Quantity','[*].LotNumber','[*].SerialNumber','[*].TransactionDate','[*].UserId','[*].ResponsibilityId'),
    pljson_varray('MOBILETRANSACTIONID','INVENTORYORGID','SOURCELPNID','DESTLPNID','INVENTORYITEMID','UOMCODE','QUANTITY','LOTNUMBER','SERIALNUMBER','TRANSACTIONDATE','USERID','RESPONSIBILITYID'),
    table_mode=>'nested'
  )
)
}';
      c_cur              sys_refcursor;
      v_rec              lpn_split_rec_type;
      l_procedure_name   VARCHAR2 (100)     := 'INSERT_LPN_SPLIT_GTT';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'Payload',
          p_payload           => 'MOBILETRANSACTIONID|INVENTORYORGID|SOURCELPNID|DESTLPNID|INVENTORYITEMID|UOMCODE|QUANTITY|LOTNUMBER|SERIALNUMBER|TRANSACTIONDATE|USERID|RESPONSIBILITYID'
         );

      OPEN c_cur FOR v_stat USING p_clob;

      LOOP
         FETCH c_cur
          INTO v_rec;

         EXIT WHEN c_cur%NOTFOUND;
         l_rec_num := l_rec_num + 1;

         INSERT INTO xxalg_lpn_lot_split_merge_gt
                     (record_grp_id, record_num, mobile_transaction_id,
                      inv_org_id, source_lpn_id,
                      dest_lpn_id, inventory_item_id, uom_code,
                      quantity, lot_number, serial_number,
                      transaction_date,
                      responsibility_id, user_id
                     )
              VALUES (p_group_id, l_rec_num, v_rec.mobiletransactionid,
                      v_rec.inventoryorgid, v_rec.sourcelpnid,
                      v_rec.destlpnid, v_rec.inventoryitemid, v_rec.uomcode,
                      v_rec.quantity, v_rec.lotnumber, v_rec.serialnumber,
                      TO_DATE (v_rec.transactiondate,
                               'DD-MON-YYYY hh24:MI:SS'),
                      v_rec.responsibilityid, v_rec.userid
                     );

         xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'Payload',
                                     p_payload           =>    v_rec.mobiletransactionid
                                                            || '|'
                                                            || v_rec.inventoryorgid
                                                            || '|'
                                                            || v_rec.sourcelpnid
                                                            || '|'
                                                            || v_rec.destlpnid
                                                            || '|'
                                                            || v_rec.inventoryitemid
                                                            || '|'
                                                            || v_rec.uomcode
                                                            || '|'
                                                            || v_rec.quantity
                                                            || '|'
                                                            || v_rec.lotnumber
                                                            || '|'
                                                            || v_rec.serialnumber
                                                            || '|'
                                                            || v_rec.transactiondate
                                                            || '|'
                                                            || v_rec.userid
                                                            || '|'
                                                            || v_rec.responsibilityid
                                    );
      END LOOP;

      CLOSE c_cur;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg :=
                l_err_msg || 'Exception in INSERT_LPN_SPLIT_GTT:-' || SQLERRM;
         x_return_msg := l_err_msg;
         DBMS_OUTPUT.put_line ('Error while INSERT_LPN_SPLIT_GTT' || SQLERRM);
         -- clear the data in table type so that none of the record will be processed.
         --p_out_data.DELETE;
         xxprop_common_util_pkg.trace_log
             (p_module            => g_package_name || '.' || l_procedure_name,
              p_message_text      =>    'Error Error while INSERT_LPN_SPLIT_GTT-'
                                     || SQLERRM,
              p_payload           => NULL
             );
   END insert_lpn_split_gtt;

   PROCEDURE insert_lot_merge_gtt (
      p_group_id        IN       NUMBER,
      p_clob            IN       CLOB,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_return_status    VARCHAR2 (10)      := 'S';
      l_err_msg          VARCHAR2 (4000);
      l_wo_index         VARCHAR2 (64);
      l_rec_num          NUMBER             := 0;
      v_stat             VARCHAR2 (1000)
         := q'{
select *
from table(
  pljson_table.json_table(
    :json_str,
    pljson_varray('[*].MobileTransactionId','[*].InventoryOrgId','[*].SourceLotNumber','[*].InventoryItemId','[*].SourceLpnId','[*].SourceSubinventoryCode','[*].SourceLocator','[*].UomCode','[*].DestLotNumber','[*].Destlpnid','[*].DestSubinventoryCode','[*].DestLocator','[*].Quantity','[*].TransactionDate','[*].UserId','[*].ResponsibilityId'),
    pljson_varray('MOBILETRANSACTIONID','INVENTORYORGID','SOURCELOTNUMBER','INVENTORYITEMID','SOURCELPNID','SOURCESUBINVENTORYCODE','SOURCELOCATOR','UOMCODE','DESTLOTNUMBER','DESTLPNID','DESTSUBINVENTORYCODE','DESTLOCATOR','QUANTITY','TRANSACTIONDATE','USERID','RESPONSIBILITYID'),
    table_mode=>'nested'
  )
)
}';
      c_cur              sys_refcursor;
      v_rec              lot_merge_rec_type;
      l_procedure_name   VARCHAR2 (100)     := 'INSERT_LOT_MERGE_GTT';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'Payload',
          p_payload           => 'MOBILETRANSACTIONID|INVENTORYORGID|SOURCELOTNUMBER|INVENTORYITEMID|SOURCELPNID|SOURCESUBINVENTORYCODE|SOURCELOCATOR|UOMCODE|DESTLOTNUMBER|DESTLPNID|DESTSUBINVENTORYCODE|DESTLOCATOR|QUANTITY|TRANSACTIONDATE|USERID|RESPONSIBILITYID'
         );

      OPEN c_cur FOR v_stat USING p_clob;

      LOOP
         FETCH c_cur
          INTO v_rec;

         EXIT WHEN c_cur%NOTFOUND;
         l_rec_num := l_rec_num + 1;

         INSERT INTO xxalg_lpn_lot_split_merge_gt
                     (record_grp_id, record_num, mobile_transaction_id,
                      inv_org_id, lot_number,
                      inventory_item_id, source_lpn_id,
                      source_sub_inventory, source_locator,
                      uom_code, dest_lot_number, dest_lpn_id,
                      dest_sub_inventory, dest_locator,
                      quantity,
                      transaction_date,
                      responsibility_id, user_id
                     )
              VALUES (p_group_id, l_rec_num, v_rec.mobiletransactionid,
                      v_rec.inventoryorgid, v_rec.sourcelotnumber,
                      v_rec.inventoryitemid, v_rec.sourcelpnid,
                      v_rec.sourcesubinventorycode, v_rec.sourcelocator,
                      v_rec.uomcode, v_rec.destlotnumber, v_rec.destlpnid,
                      v_rec.destsubinventorycode, v_rec.destlocator,
                      v_rec.quantity,
                      TO_DATE (v_rec.transactiondate,
                               'DD-MON-YYYY hh24:MI:SS'),
                      v_rec.responsibilityid, v_rec.userid
                     );

         xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Payload',
                                  p_payload           =>    v_rec.mobiletransactionid
                                                         || '|'
                                                         || v_rec.inventoryorgid
                                                         || '|'
                                                         || v_rec.sourcelotnumber
                                                         || '|'
                                                         || v_rec.inventoryitemid
                                                         || '|'
                                                         || v_rec.sourcelpnid
                                                         || '|'
                                                         || v_rec.sourcesubinventorycode
                                                         || '|'
                                                         || v_rec.sourcelocator
                                                         || '|'
                                                         || v_rec.uomcode
                                                         || '|'
                                                         || v_rec.destlotnumber
                                                         || '|'
                                                         || v_rec.destlpnid
                                                         || '|'
                                                         || v_rec.destsubinventorycode
                                                         || '|'
                                                         || v_rec.destlocator
                                                         || '|'
                                                         || v_rec.quantity
                                                         || '|'
                                                         || v_rec.transactiondate
                                                         || '|'
                                                         || v_rec.userid
                                                         || '|'
                                                         || v_rec.responsibilityid
                                 );
      END LOOP;

      CLOSE c_cur;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg :=
                l_err_msg || 'Exception in INSERT_LOT_MERGE_GTT:-' || SQLERRM;
         x_return_msg := l_err_msg;
         DBMS_OUTPUT.put_line ('Error while INSERT_LOT_MERGE_GTT' || SQLERRM);
         -- clear the data in table type so that none of the record will be processed.
         --p_out_data.DELETE;
         xxprop_common_util_pkg.trace_log
             (p_module            => g_package_name || '.' || l_procedure_name,
              p_message_text      =>    'Error Error while INSERT_LOT_MERGE_GTT-'
                                     || SQLERRM,
              p_payload           => NULL
             );
   END insert_lot_merge_gtt;
   PROCEDURE insert_lot_split_gtt (
      p_group_id        IN       NUMBER,
      p_clob            IN       CLOB,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_return_status    VARCHAR2 (10)      := 'S';
      l_err_msg          VARCHAR2 (4000);
      l_wo_index         VARCHAR2 (64);
      l_rec_num          NUMBER             := 0;
      v_stat             VARCHAR2 (1000)
         := q'{
select *
from table(
  pljson_table.json_table(
    :json_str,
    pljson_varray('[*].MobileTransactionId','[*].InventoryOrgId','[*].SourceLotNumber','[*].InventoryItemId','[*].SourceLpnId','[*].SourceSubinventoryCode','[*].SourceLocator','[*].UomCode','[*].DestLotNumber','[*].Destlpnid','[*].DestSubinventoryCode','[*].DestLocator','[*].Quantity','[*].TransactionDate','[*].UserId','[*].ResponsibilityId'),
    pljson_varray('MOBILETRANSACTIONID','INVENTORYORGID','SOURCELOTNUMBER','INVENTORYITEMID','SOURCELPNID','SOURCESUBINVENTORYCODE','SOURCELOCATOR','UOMCODE','DESTLOTNUMBER','DESTLPNID','DESTSUBINVENTORYCODE','DESTLOCATOR','QUANTITY','TRANSACTIONDATE','USERID','RESPONSIBILITYID'),
    table_mode=>'nested'
  )
)
}';
      c_cur              sys_refcursor;
      v_rec              lot_split_rec_type;
      l_procedure_name   VARCHAR2 (100)     := 'INSERT_LOT_SPLIT_GTT';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'Payload',
          p_payload           => 'MOBILETRANSACTIONID|INVENTORYORGID|SOURCELOTNUMBER|INVENTORYITEMID|SOURCELPNID|SOURCESUBINVENTORYCODE|SOURCELOCATOR|UOMCODE|DESTLOTNUMBER|DESTLPNID|DESTSUBINVENTORYCODE|DESTLOCATOR|QUANTITY|TRANSACTIONDATE|USERID|RESPONSIBILITYID'
         );

      OPEN c_cur FOR v_stat USING p_clob;

      LOOP
         FETCH c_cur
          INTO v_rec;

         EXIT WHEN c_cur%NOTFOUND;
         l_rec_num := l_rec_num + 1;

         INSERT INTO xxalg_lpn_lot_split_merge_gt
                     (record_grp_id, record_num, mobile_transaction_id,
                      inv_org_id, lot_number,
                      inventory_item_id, source_lpn_id,
                      source_sub_inventory, source_locator,
                      uom_code, dest_lot_number, dest_lpn_id,
                      dest_sub_inventory, dest_locator,
                      quantity,
                      transaction_date,
                      responsibility_id, user_id
                     )
              VALUES (p_group_id, l_rec_num, v_rec.mobiletransactionid,
                      v_rec.inventoryorgid, v_rec.sourcelotnumber,
                      v_rec.inventoryitemid, v_rec.sourcelpnid,
                      v_rec.sourcesubinventorycode, v_rec.sourcelocator,
                      v_rec.uomcode, v_rec.destlotnumber, v_rec.destlpnid,
                      v_rec.destsubinventorycode, v_rec.destlocator,
                      v_rec.quantity,
                      TO_DATE (v_rec.transactiondate,
                               'DD-MON-YYYY hh24:MI:SS'),
                      v_rec.responsibilityid, v_rec.userid
                     );

         xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Payload',
                                  p_payload           =>    v_rec.mobiletransactionid
                                                         || '|'
                                                         || v_rec.inventoryorgid
                                                         || '|'
                                                         || v_rec.sourcelotnumber
                                                         || '|'
                                                         || v_rec.inventoryitemid
                                                         || '|'
                                                         || v_rec.sourcelpnid
                                                         || '|'
                                                         || v_rec.sourcesubinventorycode
                                                         || '|'
                                                         || v_rec.sourcelocator
                                                         || '|'
                                                         || v_rec.uomcode
                                                         || '|'
                                                         || v_rec.destlotnumber
                                                         || '|'
                                                         || v_rec.destlpnid
                                                         || '|'
                                                         || v_rec.destsubinventorycode
                                                         || '|'
                                                         || v_rec.destlocator
                                                         || '|'
                                                         || v_rec.quantity
                                                         || '|'
                                                         || v_rec.transactiondate
                                                         || '|'
                                                         || v_rec.userid
                                                         || '|'
                                                         || v_rec.responsibilityid
                                 );
      END LOOP;

      CLOSE c_cur;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg :=
                l_err_msg || 'Exception in insert_lot_split_gtt:-' || SQLERRM;
         x_return_msg := l_err_msg;
         DBMS_OUTPUT.put_line ('Error while insert_lot_split_gtt' || SQLERRM);
         -- clear the data in table type so that none of the record will be processed.
         --p_out_data.DELETE;
         xxprop_common_util_pkg.trace_log
             (p_module            => g_package_name || '.' || l_procedure_name,
              p_message_text      =>    'Error Error while insert_lot_split_gtt-'
                                     || SQLERRM,
              p_payload           => NULL
             );
   END insert_lot_split_gtt;

   PROCEDURE validate_lpn_merge_data (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name           VARCHAR2 (100)  := 'VALIDATE_LPN_MERGE_DATA';
      l_record_status            VARCHAR2 (10)   := 'V';
      l_err_msg                  VARCHAR2 (1000);
      l_return_exception         EXCEPTION;
      l_check                    NUMBER;
      l_allplication_id          NUMBER;
      l_src_lpn_context          NUMBER;
      l_src_subinventory_code    VARCHAR2 (1000);
      l_src_locator_id           NUMBER;
      l_dest_lpn_context         NUMBER;
      l_dest_subinventory_code   VARCHAR2 (1000);
      l_dest_locator_id          NUMBER;

      CURSOR c_lpn_merge_cur
      IS
         SELECT *
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      FOR c_lpn_merge_rec IN c_lpn_merge_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := 'V';
         l_allplication_id := NULL;
         l_src_lpn_context := NULL;
         l_src_subinventory_code := NULL;
         l_src_locator_id := NULL;
         l_dest_lpn_context := NULL;
         l_dest_subinventory_code := NULL;
         l_dest_locator_id := NULL;

         IF c_lpn_merge_rec.responsibility_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                       l_err_msg || '|' || 'ResponsibilityId can not be null';
         ELSE
            l_allplication_id :=
               xxprop_common_util_pkg.validate_resp_id
                                           (c_lpn_merge_rec.responsibility_id);

            IF NVL (l_allplication_id, 0) <= 0
            THEN
               l_allplication_id := NULL;
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'ResponsibilityId '
                  || c_lpn_merge_rec.responsibility_id
                  || ' is not valid';
            END IF;
         END IF;

         IF c_lpn_merge_rec.user_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg := l_err_msg || '|' || 'UserId can not be null';
         ELSE
            l_check :=
               xxprop_common_util_pkg.validate_user_id
                                                     (c_lpn_merge_rec.user_id);

            IF NVL (l_check, 0) <= 0
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'UserId is  '
                  || c_lpn_merge_rec.user_id
                  || '  not valid';
            END IF;
         END IF;

         IF c_lpn_merge_rec.transaction_date IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                    l_err_msg || '|' || ' TransactionDate Should not be null';
         END IF;

         IF c_lpn_merge_rec.transaction_date > SYSDATE
         THEN
            l_record_status := 'E';
            l_err_msg :=
                  l_err_msg
               || '|'
               || 'The Transaction date '
               || REPLACE (c_lpn_merge_rec.transaction_date, ':', '')
               || ' cannot be greater than the current date';
         END IF;

         BEGIN
            IF c_lpn_merge_rec.inv_org_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                      l_err_msg || '|' || 'InventoryOrgId Should not be null';
            ELSE
               l_check :=
                  xxprop_common_util_pkg.validate_inv_period
                                           (c_lpn_merge_rec.transaction_date,
                                            c_lpn_merge_rec.inv_org_id
                                           );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Inventory Period '
                     || c_lpn_merge_rec.inv_org_id
                     || ' is not open for the given transaction date '
                     || REPLACE (c_lpn_merge_rec.transaction_date, ':', '');
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lpn_merge_rec.source_lpn_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                   l_err_msg || '|' || 'Parent/Source Lpn Should not be null';
            ELSE
               l_src_lpn_context := NULL;

               BEGIN
                  SELECT lpn_context, subinventory_code,
                         locator_id
                    INTO l_src_lpn_context, l_src_subinventory_code,
                         l_src_locator_id
                    FROM wms_license_plate_numbers
                   WHERE lpn_id = c_lpn_merge_rec.source_lpn_id
                     AND lpn_context IN (1, 5)
                     AND organization_id = c_lpn_merge_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_src_lpn_context := NULL;
               END;

               IF l_src_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Source Lpn '
                     || c_lpn_merge_rec.source_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory or Pre-generated Status';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lpn_merge_rec.dest_lpn_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Child/Destination Lpn Should not be null';
            ELSE
               l_dest_lpn_context := NULL;

               BEGIN
                  SELECT lpn_context, subinventory_code,
                         locator_id
                    INTO l_dest_lpn_context, l_dest_subinventory_code,
                         l_dest_locator_id
                    FROM wms_license_plate_numbers
                   WHERE lpn_id = c_lpn_merge_rec.dest_lpn_id
                     AND lpn_context IN (1)
                     AND organization_id = c_lpn_merge_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_dest_lpn_context := NULL;
               END;

               IF l_dest_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Child/Destination Lpn '
                     || c_lpn_merge_rec.dest_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory';
               END IF;
            END IF;
         END;

         /*BEGIN
            l_check := 0;

            BEGIN
               SELECT COUNT (*)
                 INTO l_check
                 FROM (SELECT DISTINCT msi.item_type
                                  FROM mtl_system_items_b msi,
                                       wms_lpn_contents wlc
                                 WHERE wlc.organization_id =
                                                           msi.organization_id
                                   AND wlc.inventory_item_id =
                                                         msi.inventory_item_id
                                   AND wlc.parent_lpn_id =
                                                 c_lpn_merge_rec.source_lpn_id
                       UNION
                       SELECT DISTINCT msi.item_type
                                  FROM mtl_system_items_b msi,
                                       wms_lpn_contents wlc
                                 WHERE wlc.organization_id =
                                                           msi.organization_id
                                   AND wlc.inventory_item_id =
                                                         msi.inventory_item_id
                                   AND wlc.parent_lpn_id =
                                                   c_lpn_merge_rec.dest_lpn_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_check := 0;
            END;

            IF l_check > 1
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Item Type of item residing in Parent/Source and Child/Destination Lpn are not same';
            END IF;
         END;*/
         IF (l_src_lpn_context = 1 AND l_dest_lpn_context = 1)
         THEN
            IF NVL (l_src_subinventory_code, 'XXXX') <>
                                       NVL (l_dest_subinventory_code, 'XXXX')
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Parent/Source Subinventory not matching with Child/Destination Subinventory';
            END IF;

            IF NVL (l_src_locator_id, -9999) <> NVL (l_dest_locator_id, -9999)
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Parent/Source Locator not matching with Child/Destination Locator';
            END IF;
         END IF;

         UPDATE xxalg_lpn_lot_split_merge_gt
            SET resp_application_id = l_allplication_id,
                transaction_action_id = 50,
                transaction_type_id = 87,
                transaction_source_type_id = 13,
                source_sub_inventory =
                       NVL (l_src_subinventory_code, l_dest_subinventory_code),
                source_locator_id = NVL (l_src_locator_id, l_dest_locator_id),
                record_status = l_record_status,
                record_message = l_err_msg
          WHERE record_num = c_lpn_merge_rec.record_num
            AND record_grp_id = p_group_id;

         xxprop_common_util_pkg.trace_log
                          (p_module            =>    g_package_name
                                                  || '.'
                                                  || l_procedure_name,
                           p_message_text      =>    'Validation Record Message- '
                                                  || l_err_msg,
                           p_payload           => NULL
                          );
      END LOOP;

      BEGIN
         SELECT COUNT (*)
           INTO l_check
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id AND record_status = 'V';
      END;

      IF l_check > 0
      THEN
         x_return_status := 'S';
      ELSE
         x_return_status := 'E';
      END IF;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg := 'Exception in validate_lpn_merge_data:-' || SQLERRM;
         x_return_msg := l_err_msg;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => l_err_msg,
                                           p_payload           => NULL
                                          );
   END validate_lpn_merge_data;

   PROCEDURE validate_lpn_split_data (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name               VARCHAR2 (100)
                                                 := 'VALIDATE_LPN_SPLIT_DATA';
      l_record_status                VARCHAR2 (10)   := 'V';
      l_err_msg                      VARCHAR2 (1000);
      l_return_exception             EXCEPTION;
      l_check                        NUMBER;
      l_allplication_id              NUMBER;
      l_src_lpn_context              NUMBER;
      l_src_subinventory_code        VARCHAR2 (1000);
      l_src_locator_id               NUMBER;
      l_dest_lpn_context             NUMBER;
      l_dest_subinventory_code       VARCHAR2 (1000);
      l_dest_locator_id              NUMBER;
      l_lot_control_code             VARCHAR2 (100);
      l_serial_number_control_code   VARCHAR2 (100);
      l_transactable_qty             NUMBER;
      l_qoh                          NUMBER;
      l_lpn_onhand                   NUMBER;
      l_api_return_msg               VARCHAR2 (4000);
      l_unpack_item_qty_val          VARCHAR2 (200);
      l_sec_uom_code                 VARCHAR2 (100);
      l_sec_qty                      NUMBER;

      CURSOR c_lpn_split_cur
      IS
         SELECT *
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      FOR c_lpn_split_rec IN c_lpn_split_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := 'V';
         l_allplication_id := NULL;
         l_src_lpn_context := NULL;
         l_src_subinventory_code := NULL;
         l_src_locator_id := NULL;
         l_dest_lpn_context := NULL;
         l_dest_subinventory_code := NULL;
         l_dest_locator_id := NULL;
         l_lot_control_code := NULL;
         l_serial_number_control_code := NULL;
         l_transactable_qty := NULL;
         l_qoh := NULL;
         l_lpn_onhand := NULL;
         l_api_return_msg := NULL;
         l_unpack_item_qty_val := NULL;
         l_sec_uom_code := NULL;
         l_sec_qty := NULL;

         IF c_lpn_split_rec.responsibility_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                       l_err_msg || '|' || 'ResponsibilityId can not be null';
         ELSE
            l_allplication_id :=
               xxprop_common_util_pkg.validate_resp_id
                                           (c_lpn_split_rec.responsibility_id);

            IF NVL (l_allplication_id, 0) <= 0
            THEN
               l_allplication_id := NULL;
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'ResponsibilityId '
                  || c_lpn_split_rec.responsibility_id
                  || ' is not valid';
            END IF;
         END IF;

         IF c_lpn_split_rec.user_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg := l_err_msg || '|' || 'UserId can not be null';
         ELSE
            l_check :=
               xxprop_common_util_pkg.validate_user_id
                                                     (c_lpn_split_rec.user_id);

            IF NVL (l_check, 0) <= 0
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'UserId is  '
                  || c_lpn_split_rec.user_id
                  || '  not valid';
            END IF;
         END IF;

         IF c_lpn_split_rec.transaction_date IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                    l_err_msg || '|' || ' TransactionDate Should not be null';
         END IF;

         IF c_lpn_split_rec.transaction_date > SYSDATE
         THEN
            l_record_status := 'E';
            l_err_msg :=
                  l_err_msg
               || '|'
               || 'The Transaction date '
               || REPLACE (c_lpn_split_rec.transaction_date, ':', '')
               || ' cannot be greater than the current date';
         END IF;

         BEGIN
            IF c_lpn_split_rec.inv_org_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                      l_err_msg || '|' || 'InventoryOrgId Should not be null';
            ELSE
               l_check :=
                  xxprop_common_util_pkg.validate_inv_period
                                           (c_lpn_split_rec.transaction_date,
                                            c_lpn_split_rec.inv_org_id
                                           );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Inventory Period '
                     || c_lpn_split_rec.inv_org_id
                     || ' is not open for the given transaction date '
                     || REPLACE (c_lpn_split_rec.transaction_date, ':', '');
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lpn_split_rec.source_lpn_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                   l_err_msg || '|' || 'Parent/Source Lpn Should not be null';
            ELSE
               l_src_lpn_context := NULL;

               BEGIN
                  SELECT lpn_context, subinventory_code,
                         locator_id
                    INTO l_src_lpn_context, l_src_subinventory_code,
                         l_src_locator_id
                    FROM wms_license_plate_numbers
                   WHERE lpn_id = c_lpn_split_rec.source_lpn_id
                     AND lpn_context IN (1)
                     AND organization_id = c_lpn_split_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_src_lpn_context := NULL;
               END;

               IF l_src_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Source Lpn '
                     || c_lpn_split_rec.source_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lpn_split_rec.dest_lpn_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Child/Destination Lpn Should not be null';
            ELSE
               l_dest_lpn_context := NULL;

               BEGIN
                  SELECT lpn_context, subinventory_code,
                         locator_id
                    INTO l_dest_lpn_context, l_dest_subinventory_code,
                         l_dest_locator_id
                    FROM wms_license_plate_numbers
                   WHERE lpn_id = c_lpn_split_rec.dest_lpn_id
                     AND lpn_context IN (1, 5)
                     AND organization_id = c_lpn_split_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_dest_lpn_context := NULL;
               END;

               IF l_dest_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Child/Destination Lpn '
                     || c_lpn_split_rec.dest_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory or Pre-generated Status';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lpn_split_rec.inventory_item_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg := l_err_msg || '|' || 'Item Id Should not be null';
            ELSE
               BEGIN
                  SELECT DECODE (msi.lot_control_code, 2, 'TRUE', 'FALSE'),
                         DECODE (msi.serial_number_control_code,
                                 2, 'TRUE',
                                 5, 'TRUE',
                                 'FALSE'
                                )
                    INTO l_lot_control_code,
                         l_serial_number_control_code
                    FROM mtl_system_items_b msi
                   WHERE 1 = 1
                     AND msi.inventory_item_id =
                                             c_lpn_split_rec.inventory_item_id
                     AND msi.organization_id = c_lpn_split_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_record_status := 'E';
                     l_err_msg :=
                           l_err_msg
                        || '|'
                        || 'Inventory Item Id'
                        || c_lpn_split_rec.inventory_item_id
                        || ' is Not Valid';
               END;
            END IF;
         END;

         IF     l_serial_number_control_code = 'TRUE'
            AND c_lpn_split_rec.inventory_item_id IS NOT NULL
         THEN
            IF c_lpn_split_rec.serial_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Serial number is null but item is Serial Control, Please pass Serial number.';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM mtl_serial_numbers msn
                WHERE inventory_item_id = c_lpn_split_rec.inventory_item_id
                  AND owning_organization_id = c_lpn_split_rec.inv_org_id
                  AND serial_number = c_lpn_split_rec.serial_number
                  AND lpn_id = c_lpn_split_rec.source_lpn_id;

               IF l_check = 0                                             -- 2
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Serial Number Not Valid or not Residing into the Parent/Source Lpn';
               END IF;
            END IF;
         END IF;

         IF     l_lot_control_code = 'TRUE'
            AND c_lpn_split_rec.inventory_item_id IS NOT NULL
         THEN
            IF c_lpn_split_rec.lot_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Lot number is null but item is Lot Control, Please pass lot number.';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM wms_lpn_contents
                WHERE inventory_item_id = c_lpn_split_rec.inventory_item_id
                  AND lot_number = c_lpn_split_rec.lot_number
                  AND organization_id = c_lpn_split_rec.inv_org_id;

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Lot Number Not Valid or not Residing into the Parent/Source Lpn';
               END IF;
            END IF;
         END IF;

         IF (l_src_lpn_context = 1 AND l_dest_lpn_context = 1)
         THEN
            IF NVL (l_src_subinventory_code, 'XXXX') <>
                                       NVL (l_dest_subinventory_code, 'XXXX')
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Parent/Source Subinventory not matching with Child/Destination Subinventory';
            END IF;

            IF NVL (l_src_locator_id, -9999) <> NVL (l_dest_locator_id, -9999)
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Parent/Source Locator not matching with Child/Destination Locator';
            END IF;
         END IF;

         BEGIN
            IF NVL (c_lpn_split_rec.quantity, 0) = 0
            THEN
               l_record_status := 'E';
               l_err_msg :=
                      l_err_msg || '|' || 'Quantity Should be greater than 0';
            ELSE
               BEGIN
                  l_unpack_item_qty_val :=
                     inv_txn_validations.get_unpacksplit_lpn_item_qty
                        (p_lpn_id                          => c_lpn_split_rec.source_lpn_id,
                         p_organization_id                 => c_lpn_split_rec.inv_org_id,
                         p_source_type_id                  => 13,
                         p_inventory_item_id               => c_lpn_split_rec.inventory_item_id,
                         p_revision                        => NULL,
                         p_locator_id                      => l_src_locator_id,
                         p_subinventory_code               => l_src_subinventory_code,
                         p_lot_number                      => c_lpn_split_rec.lot_number,
                         p_is_revision_control             => 'FALSE',
                         p_is_serial_control               => l_serial_number_control_code,
                         p_is_lot_control                  => l_lot_control_code,
                         p_transfer_subinventory_code      => l_src_subinventory_code,
                         p_transfer_locator_id             => l_src_locator_id,
                         x_transactable_qty                => l_transactable_qty,
                         x_qoh                             => l_qoh,
                         x_lpn_onhand                      => l_lpn_onhand,
                         x_return_msg                      => l_api_return_msg,
                         p_is_clear_quantity_cache         => 'FALSE'
                        );
               END;

               IF l_unpack_item_qty_val = 'Y'
               THEN
                  IF c_lpn_split_rec.quantity > l_transactable_qty
                  THEN
                     l_record_status := 'E';
                     l_err_msg :=
                           l_err_msg
                        || '|'
                        || 'Quantity greater than the available quantity in Parent/Source LPN';
                  END IF;
               ELSE
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Error While calling Validation API-'
                     || l_api_return_msg;
               END IF;

               IF l_serial_number_control_code = 'TRUE'
               THEN
                  l_unpack_item_qty_val := NULL;
                  l_unpack_item_qty_val :=
                     inv_txn_validations.check_serial_unpacksplit
                             (p_lpn_id       => c_lpn_split_rec.source_lpn_id,
                              p_org_id       => c_lpn_split_rec.inv_org_id,
                              p_item_id      => c_lpn_split_rec.inventory_item_id,
                              p_rev          => NULL,
                              p_lot          => c_lpn_split_rec.lot_number,
                              p_serial       => c_lpn_split_rec.serial_number
                             );

                  IF l_unpack_item_qty_val <> 'Y'
                  THEN
                     l_record_status := 'E';
                     l_err_msg :=
                           l_err_msg
                        || '|'
                        || 'This item With Serial Number '
                        || c_lpn_split_rec.serial_number
                        || ' is Allocated with other Transaction, Please release earlier transaction then try again';
                  END IF;
               END IF;
            END IF;

            BEGIN
               SELECT msi.secondary_uom_code
                 INTO l_sec_uom_code
                 FROM apps.mtl_system_items_b msi
                WHERE 1 = 1
                  AND msi.secondary_uom_code IS NOT NULL
                  AND msi.tracking_quantity_ind = 'PS'
                  AND msi.dual_uom_control = 2
                  AND msi.organization_id = c_lpn_split_rec.inv_org_id
                  AND msi.inventory_item_id =
                                             c_lpn_split_rec.inventory_item_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_sec_uom_code := NULL;
            END;
         END;

         IF l_sec_uom_code IS NOT NULL
         THEN
            l_sec_qty :=
               inv_convert.inv_um_convert
                              (item_id              => c_lpn_split_rec.inventory_item_id,
                               lot_number           => c_lpn_split_rec.lot_number,
                               organization_id      => c_lpn_split_rec.inv_org_id,
                               PRECISION            => NULL,
                               from_quantity        => c_lpn_split_rec.quantity,
                               from_unit            => c_lpn_split_rec.uom_code,
                               to_unit              => l_sec_uom_code,
                               from_name            => NULL,
                               to_name              => NULL
                              );

            IF l_sec_qty = -99999
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Error while pulling the Secondory Qty inv_convert.inv_um_convert Error ';
            END IF;
         END IF;

         UPDATE xxalg_lpn_lot_split_merge_gt
            SET resp_application_id = l_allplication_id,
                transaction_action_id = 52,
                transaction_type_id = 89,
                transaction_source_type_id = 13,
                secondary_uom_code = l_sec_uom_code,
                secondary_quantity = l_sec_qty,
                source_sub_inventory =
                       NVL (l_src_subinventory_code, l_dest_subinventory_code),
                source_locator_id = NVL (l_src_locator_id, l_dest_locator_id),
                record_status = l_record_status,
                record_message = l_err_msg
          WHERE record_num = c_lpn_split_rec.record_num
            AND record_grp_id = p_group_id;

         xxprop_common_util_pkg.trace_log
                          (p_module            =>    g_package_name
                                                  || '.'
                                                  || l_procedure_name,
                           p_message_text      =>    'Validation Record Message- '
                                                  || l_err_msg,
                           p_payload           => NULL
                          );
      END LOOP;

      BEGIN
         SELECT COUNT (*)
           INTO l_check
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id AND record_status = 'V';
      END;

      IF l_check > 0
      THEN
         x_return_status := 'S';
      ELSE
         x_return_status := 'E';
      END IF;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg := 'Exception in validate_lpn_split_data:-' || SQLERRM;
         x_return_msg := l_err_msg;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => l_err_msg,
                                           p_payload           => NULL
                                          );
   END validate_lpn_split_data;

   PROCEDURE validate_lot_merge_data (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name               VARCHAR2 (100)
                                                 := 'VALIDATE_LOT_MERGE_DATA';
      l_record_status                VARCHAR2 (10)   := 'V';
      l_err_msg                      VARCHAR2 (1000);
      l_return_exception             EXCEPTION;
      l_check                        NUMBER;
      l_allplication_id              NUMBER;
      l_src_lpn_context              NUMBER;
      l_src_subinventory_code        VARCHAR2 (1000);
      l_src_locator_id               NUMBER;
      l_src_lpn_subinventory_code    VARCHAR2 (1000);
      l_src_lpn_locator_id           NUMBER;
      l_dest_lpn_subinventory_code   VARCHAR2 (1000);
      l_dest_lpn_locator_id          NUMBER;
      l_dest_lpn_context             NUMBER;
      l_dest_subinventory_code       VARCHAR2 (1000);
      l_dest_locator_id              NUMBER;
      l_lot_control_code             VARCHAR2 (100);
      l_serial_number_control_code   VARCHAR2 (100);
      l_transactable_qty             NUMBER;
      l_qoh                          NUMBER;
      l_lpn_onhand                   NUMBER;
      l_api_return_msg               VARCHAR2 (4000);
      l_unpack_item_qty_val          VARCHAR2 (200);
      l_sec_uom_code                 VARCHAR2 (100);
      l_sec_qty                      NUMBER;

      CURSOR c_lot_merge_cur
      IS
         SELECT *
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      FOR c_lot_merge_rec IN c_lot_merge_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := 'V';
         l_allplication_id := NULL;
         l_src_lpn_context := NULL;
         l_src_subinventory_code := NULL;
         l_src_locator_id := NULL;
         l_src_lpn_subinventory_code := NULL;
         l_src_lpn_locator_id := NULL;
         l_dest_lpn_subinventory_code := NULL;
         l_dest_lpn_locator_id := NULL;
         l_dest_lpn_context := NULL;
         l_dest_subinventory_code := NULL;
         l_dest_locator_id := NULL;
         l_lot_control_code := NULL;
         l_serial_number_control_code := NULL;
         l_transactable_qty := NULL;
         l_qoh := NULL;
         l_lpn_onhand := NULL;
         l_api_return_msg := NULL;
         l_unpack_item_qty_val := NULL;
         l_sec_uom_code := NULL;
         l_sec_qty := NULL;

         IF c_lot_merge_rec.responsibility_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                       l_err_msg || '|' || 'ResponsibilityId can not be null';
         ELSE
            l_allplication_id :=
               xxprop_common_util_pkg.validate_resp_id
                                           (c_lot_merge_rec.responsibility_id);

            IF NVL (l_allplication_id, 0) <= 0
            THEN
               l_allplication_id := NULL;
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'ResponsibilityId '
                  || c_lot_merge_rec.responsibility_id
                  || ' is not valid';
            END IF;
         END IF;

         IF c_lot_merge_rec.user_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg := l_err_msg || '|' || 'UserId can not be null';
         ELSE
            l_check :=
               xxprop_common_util_pkg.validate_user_id
                                                     (c_lot_merge_rec.user_id);

            IF NVL (l_check, 0) <= 0
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'UserId is  '
                  || c_lot_merge_rec.user_id
                  || '  not valid';
            END IF;
         END IF;

         IF c_lot_merge_rec.transaction_date IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                    l_err_msg || '|' || ' TransactionDate Should not be null';
         END IF;

         IF c_lot_merge_rec.transaction_date > SYSDATE
         THEN
            l_record_status := 'E';
            l_err_msg :=
                  l_err_msg
               || '|'
               || 'The Transaction date '
               || REPLACE (c_lot_merge_rec.transaction_date, ':', '')
               || ' cannot be greater than the current date';
         END IF;

         BEGIN
            IF c_lot_merge_rec.inv_org_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                      l_err_msg || '|' || 'InventoryOrgId Should not be null';
            ELSE
               l_check :=
                  xxprop_common_util_pkg.validate_inv_period
                                           (c_lot_merge_rec.transaction_date,
                                            c_lot_merge_rec.inv_org_id
                                           );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Inventory Period '
                     || c_lot_merge_rec.inv_org_id
                     || ' is not open for the given transaction date '
                     || REPLACE (c_lot_merge_rec.transaction_date, ':', '');
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.inventory_item_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg := l_err_msg || '|' || 'Item Id Should not be null';
            ELSE
               BEGIN
                  SELECT DECODE (msi.lot_control_code, 2, 'TRUE', 'FALSE'),
                         DECODE (msi.serial_number_control_code,
                                 2, 'TRUE',
                                 5, 'TRUE',
                                 'FALSE'
                                )
                    INTO l_lot_control_code,
                         l_serial_number_control_code
                    FROM mtl_system_items_b msi
                   WHERE 1 = 1
                     AND msi.inventory_item_id =
                                             c_lot_merge_rec.inventory_item_id
                     AND msi.organization_id = c_lot_merge_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_record_status := 'E';
                     l_err_msg :=
                           l_err_msg
                        || '|'
                        || 'Inventory Item Id'
                        || c_lot_merge_rec.inventory_item_id
                        || ' is Not Valid';
               END;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.lot_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Parent/Source LotNumber Should not be null';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM mtl_lot_numbers
                WHERE inventory_item_id = c_lot_merge_rec.inventory_item_id
                  AND lot_number = c_lot_merge_rec.lot_number
                  AND organization_id = c_lot_merge_rec.inv_org_id;

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Source LotNumber '
                     || c_lot_merge_rec.lot_number
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.source_lpn_id IS NOT NULL
            THEN
               l_src_lpn_context := NULL;
               l_src_lpn_subinventory_code := NULL;
               l_src_lpn_locator_id := NULL;

               BEGIN
                  SELECT DISTINCT lpn_context,
                                  subinventory_code,
                                  locator_id
                             INTO l_src_lpn_context,
                                  l_src_lpn_subinventory_code,
                                  l_src_lpn_locator_id
                             FROM wms_license_plate_numbers wlpn,
                                  wms_lpn_contents wlc
                            WHERE wlpn.lpn_id = c_lot_merge_rec.source_lpn_id
                              AND wlpn.lpn_context IN (1)
                              AND wlpn.organization_id =
                                                    c_lot_merge_rec.inv_org_id
                              AND wlc.inventory_item_id =
                                             c_lot_merge_rec.inventory_item_id
                              AND wlpn.lpn_id = wlc.parent_lpn_id
                              AND wlc.lot_number = c_lot_merge_rec.lot_number
                              AND wlc.organization_id = wlpn.organization_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_src_lpn_context := NULL;
               END;

               IF l_src_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Source Lpn '
                     || c_lot_merge_rec.source_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.source_sub_inventory IS NOT NULL
            THEN
               l_check := 0;
               l_check :=
                  xxprop_common_util_pkg.validate_subinventory
                                       (c_lot_merge_rec.source_sub_inventory,
                                        c_lot_merge_rec.inv_org_id
                                       );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Source SubInventory '
                     || c_lot_merge_rec.source_sub_inventory
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.source_locator IS NOT NULL
            THEN
               l_src_locator_id := 0;
               l_src_locator_id :=
                  xxprop_common_util_pkg.validate_locator
                                       (c_lot_merge_rec.source_locator,
                                        c_lot_merge_rec.source_sub_inventory,
                                        c_lot_merge_rec.inv_org_id
                                       );

               IF l_src_locator_id <= 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Source Locator '
                     || c_lot_merge_rec.source_locator
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         IF c_lot_merge_rec.source_lpn_id IS NOT NULL
         THEN
            IF NVL (l_src_lpn_subinventory_code,
                    NVL (c_lot_merge_rec.source_sub_inventory, 'XXXX')
                   ) <>
                  NVL (c_lot_merge_rec.source_sub_inventory,
                       NVL (l_src_lpn_subinventory_code, 'XXXX')
                      )
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Source SubInventory '
                  || c_lot_merge_rec.source_sub_inventory
                  || ' is not Matching with LPN Subinventory '
                  || l_src_lpn_subinventory_code;
            END IF;

            IF NVL (l_src_lpn_locator_id, NVL (l_src_locator_id, -1)) <>
                         NVL (l_src_locator_id, NVL (l_src_lpn_locator_id, -1))
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Source Locator '
                  || c_lot_merge_rec.source_locator
                  || ' is not Matching with LPN Locator ';
            END IF;
         END IF;

         BEGIN
            IF c_lot_merge_rec.dest_lot_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Child/Destination LotNumber Should not be null';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM mtl_lot_numbers
                WHERE 1 = 1
                  --inventory_item_id = c_lot_merge_rec.inventory_item_id
                  AND lot_number = c_lot_merge_rec.dest_lot_number
                  AND organization_id = c_lot_merge_rec.inv_org_id;

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Child/Destination LotNumber '
                     || c_lot_merge_rec.lot_number
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.dest_lpn_id IS NOT NULL
            THEN
               l_dest_lpn_context := NULL;
               l_dest_lpn_subinventory_code := NULL;
               l_dest_lpn_locator_id := NULL;

               BEGIN
                  SELECT DISTINCT lpn_context,
                                  subinventory_code,
                                  locator_id
                             INTO l_dest_lpn_context,
                                  l_dest_lpn_subinventory_code,
                                  l_dest_lpn_locator_id
                             FROM wms_license_plate_numbers wlpn
                            WHERE wlpn.lpn_id = c_lot_merge_rec.dest_lpn_id
                              AND wlpn.lpn_context IN (1, 5)
                              AND wlpn.organization_id =
                                                    c_lot_merge_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_dest_lpn_context := NULL;
               END;

               IF l_dest_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Dest Lpn '
                     || c_lot_merge_rec.dest_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory or Pre-generated Status';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.dest_sub_inventory IS NOT NULL
            THEN
               l_check := 0;
               l_check :=
                  xxprop_common_util_pkg.validate_subinventory
                                         (c_lot_merge_rec.dest_sub_inventory,
                                          c_lot_merge_rec.inv_org_id
                                         );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Dest SubInventory '
                     || c_lot_merge_rec.dest_sub_inventory
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_merge_rec.dest_locator IS NOT NULL
            THEN
               l_dest_locator_id := 0;
               l_dest_locator_id :=
                  xxprop_common_util_pkg.validate_locator
                                         (c_lot_merge_rec.dest_locator,
                                          c_lot_merge_rec.dest_sub_inventory,
                                          c_lot_merge_rec.inv_org_id
                                         );

               IF l_dest_locator_id <= 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Dest Locator '
                     || c_lot_merge_rec.dest_locator
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         IF c_lot_merge_rec.dest_lpn_id IS NOT NULL
         THEN
            IF NVL (l_dest_lpn_subinventory_code,
                    NVL (c_lot_merge_rec.dest_sub_inventory, 'XXXX')
                   ) <>
                  NVL (c_lot_merge_rec.dest_sub_inventory,
                       NVL (l_dest_lpn_subinventory_code, 'XXXX')
                      )
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Dest SubInventory '
                  || c_lot_merge_rec.dest_sub_inventory
                  || ' is not Matching with LPN Subinventory '
                  || l_dest_lpn_subinventory_code;
            END IF;

            IF NVL (l_dest_lpn_locator_id, NVL (l_dest_locator_id, -1)) <>
                       NVL (l_dest_locator_id, NVL (l_dest_lpn_locator_id, -1))
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Dest Locator '
                  || c_lot_merge_rec.dest_locator
                  || ' is not Matching with LPN Locator ';
            END IF;
         END IF;

         /*IF     l_serial_number_control_code = 'TRUE'
            AND c_lot_merge_rec.inventory_item_id IS NOT NULL
         THEN
            IF c_lot_merge_rec.serial_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Serial number is null but item is Serial Control, Please pass Serial number.';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM mtl_serial_numbers msn
                WHERE inventory_item_id = c_lot_merge_rec.inventory_item_id
                  AND owning_organization_id = c_lot_merge_rec.inv_org_id
                  AND serial_number = c_lot_merge_rec.serial_number
                  AND lpn_id = NVL (c_lot_merge_rec.source_lpn_id, lpn_id);

               IF l_check = 0                                             -- 2
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Serial Number Not Valid or not Residing into the Parent/Source Lpn';
               END IF;
            END IF;
         END IF;*/
         BEGIN
            IF NVL (c_lot_merge_rec.quantity, 0) = 0
            THEN
               l_record_status := 'E';
               l_err_msg :=
                      l_err_msg || '|' || 'Quantity Should be greater than 0';
            ELSE
               BEGIN
                  l_unpack_item_qty_val :=
                     inv_txn_validations.get_immediate_lpn_item_qty
                        (p_lpn_id                       => NULL,
                         p_organization_id              => c_lot_merge_rec.inv_org_id,
                         p_source_type_id               => -9999,
                         p_inventory_item_id            => c_lot_merge_rec.inventory_item_id,
                         p_revision                     => NULL,
                         p_locator_id                   => NVL
                                                              (l_src_lpn_locator_id,
                                                               l_src_locator_id
                                                              ),
                         p_subinventory_code            => NVL
                                                              (l_src_lpn_subinventory_code,
                                                               c_lot_merge_rec.source_sub_inventory
                                                              ),
                         p_lot_number                   => c_lot_merge_rec.lot_number,
                         p_is_revision_control          => 'FALSE',
                         p_is_serial_control            => l_serial_number_control_code,
                         p_is_lot_control               => 'TRUE',
                         x_transactable_qty             => l_transactable_qty,
                         x_qoh                          => l_qoh,
                         x_lpn_onhand                   => l_lpn_onhand,
                         x_return_msg                   => l_api_return_msg,
                         p_is_clear_quantity_cache      => 'TRUE'
                        );
               END;

               DBMS_OUTPUT.put_line (   'l_transactable_qty-'
                                     || l_transactable_qty
                                    );
               DBMS_OUTPUT.put_line (' l_qoh=' || l_qoh);
               DBMS_OUTPUT.put_line (' l_lpn_onhand=' || l_lpn_onhand);

               IF l_unpack_item_qty_val = 'Y'
               THEN
                  IF c_lot_merge_rec.quantity > l_qoh    --l_transactable_qty
                  THEN
                     l_record_status := 'E';
                     l_err_msg :=
                           l_err_msg
                        || '|'
                        || 'Quantity greater than the available quantity ';
                  END IF;
               ELSE
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Error While calling getting available quantity API-'
                     || l_api_return_msg;
               END IF;
            END IF;

            BEGIN
               SELECT msi.secondary_uom_code
                 INTO l_sec_uom_code
                 FROM apps.mtl_system_items_b msi
                WHERE 1 = 1
                  AND msi.secondary_uom_code IS NOT NULL
                  AND msi.tracking_quantity_ind = 'PS'
                  AND msi.dual_uom_control = 2
                  AND msi.organization_id = c_lot_merge_rec.inv_org_id
                  AND msi.inventory_item_id =
                                             c_lot_merge_rec.inventory_item_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_sec_uom_code := NULL;
            END;
         END;

         IF l_sec_uom_code IS NOT NULL
         THEN
            l_sec_qty :=
               inv_convert.inv_um_convert
                              (item_id              => c_lot_merge_rec.inventory_item_id,
                               lot_number           => c_lot_merge_rec.lot_number,
                               organization_id      => c_lot_merge_rec.inv_org_id,
                               PRECISION            => NULL,
                               from_quantity        => c_lot_merge_rec.quantity,
                               from_unit            => c_lot_merge_rec.uom_code,
                               to_unit              => l_sec_uom_code,
                               from_name            => NULL,
                               to_name              => NULL
                              );

            IF l_sec_qty = -99999
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Error while pulling the Secondory Qty inv_convert.inv_um_convert Error ';
            END IF;
         END IF;

         UPDATE xxalg_lpn_lot_split_merge_gt
            SET resp_application_id = l_allplication_id,
                transaction_action_id = 41,
                transaction_type_id = 83,
                transaction_source_type_id = 13,
                secondary_uom_code = l_sec_uom_code,
                secondary_quantity = l_sec_qty,
                source_sub_inventory =
                   NVL (l_src_lpn_subinventory_code,
                        c_lot_merge_rec.source_sub_inventory
                       ),
                source_locator_id =
                                  NVL (l_src_lpn_locator_id, l_src_locator_id),
                dest_sub_inventory =
                   NVL (l_dest_lpn_subinventory_code,
                        c_lot_merge_rec.dest_sub_inventory
                       ),
                dest_locator_id =
                                NVL (l_dest_lpn_locator_id, l_dest_locator_id),
                record_status = l_record_status,
                record_message = l_err_msg
          WHERE record_num = c_lot_merge_rec.record_num
            AND record_grp_id = p_group_id;

         xxprop_common_util_pkg.trace_log
                          (p_module            =>    g_package_name
                                                  || '.'
                                                  || l_procedure_name,
                           p_message_text      =>    'Validation Record Message- '
                                                  || l_err_msg,
                           p_payload           => NULL
                          );
      END LOOP;

      BEGIN
         SELECT COUNT (*)
           INTO l_check
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id AND record_status = 'V';
      END;

      IF l_check > 0
      THEN
         x_return_status := 'S';
      ELSE
         x_return_status := 'E';
      END IF;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg := 'Exception in VALIDATE_LOT_MERGE_DATA:-' || SQLERRM;
         x_return_msg := l_err_msg;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => l_err_msg,
                                           p_payload           => NULL
                                          );
   END validate_lot_merge_data;
PROCEDURE validate_lot_split_data (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name               VARCHAR2 (100)
                                                 := 'validate_lot_split_data';
      l_record_status                VARCHAR2 (10)   := 'V';
      l_err_msg                      VARCHAR2 (1000);
      l_return_exception             EXCEPTION;
      l_check                        NUMBER;
      l_allplication_id              NUMBER;
      l_src_lpn_context              NUMBER;
      l_src_subinventory_code        VARCHAR2 (1000);
      l_src_locator_id               NUMBER;
      l_src_lpn_subinventory_code    VARCHAR2 (1000);
      l_src_lpn_locator_id           NUMBER;
      l_dest_lpn_subinventory_code   VARCHAR2 (1000);
      l_dest_lpn_locator_id          NUMBER;
      l_dest_lpn_context             NUMBER;
      l_dest_subinventory_code       VARCHAR2 (1000);
      l_dest_locator_id              NUMBER;
      l_lot_control_code             VARCHAR2 (100);
      l_serial_number_control_code   VARCHAR2 (100);
      l_transactable_qty             NUMBER;
      l_qoh                          NUMBER;
      l_lpn_onhand                   NUMBER;
      l_api_return_msg               VARCHAR2 (4000);
      l_unpack_item_qty_val          VARCHAR2 (200);
      l_sec_uom_code                 VARCHAR2 (100);
      l_sec_qty                      NUMBER;

      CURSOR c_lot_split_cur
      IS
         SELECT *
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      FOR c_lot_split_rec IN c_lot_split_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := 'V';
         l_allplication_id := NULL;
         l_src_lpn_context := NULL;
         l_src_subinventory_code := NULL;
         l_src_locator_id := NULL;
         l_src_lpn_subinventory_code := NULL;
         l_src_lpn_locator_id := NULL;
         l_dest_lpn_subinventory_code := NULL;
         l_dest_lpn_locator_id := NULL;
         l_dest_lpn_context := NULL;
         l_dest_subinventory_code := NULL;
         l_dest_locator_id := NULL;
         l_lot_control_code := NULL;
         l_serial_number_control_code := NULL;
         l_transactable_qty := NULL;
         l_qoh := NULL;
         l_lpn_onhand := NULL;
         l_api_return_msg := NULL;
         l_unpack_item_qty_val := NULL;
         l_sec_uom_code := NULL;
         l_sec_qty := NULL;

         IF c_lot_split_rec.responsibility_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                       l_err_msg || '|' || 'ResponsibilityId can not be null';
         ELSE
            l_allplication_id :=
               xxprop_common_util_pkg.validate_resp_id
                                           (c_lot_split_rec.responsibility_id);

            IF NVL (l_allplication_id, 0) <= 0
            THEN
               l_allplication_id := NULL;
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'ResponsibilityId '
                  || c_lot_split_rec.responsibility_id
                  || ' is not valid';
            END IF;
         END IF;

         IF c_lot_split_rec.user_id IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg := l_err_msg || '|' || 'UserId can not be null';
         ELSE
            l_check :=
               xxprop_common_util_pkg.validate_user_id
                                                     (c_lot_split_rec.user_id);

            IF NVL (l_check, 0) <= 0
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'UserId is  '
                  || c_lot_split_rec.user_id
                  || '  not valid';
            END IF;
         END IF;

         IF c_lot_split_rec.transaction_date IS NULL
         THEN
            l_record_status := 'E';
            l_err_msg :=
                    l_err_msg || '|' || ' TransactionDate Should not be null';
         END IF;

         IF c_lot_split_rec.transaction_date > SYSDATE
         THEN
            l_record_status := 'E';
            l_err_msg :=
                  l_err_msg
               || '|'
               || 'The Transaction date '
               || REPLACE (c_lot_split_rec.transaction_date, ':', '')
               || ' cannot be greater than the current date';
         END IF;

         BEGIN
            IF c_lot_split_rec.inv_org_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                      l_err_msg || '|' || 'InventoryOrgId Should not be null';
            ELSE
               l_check :=
                  xxprop_common_util_pkg.validate_inv_period
                                           (c_lot_split_rec.transaction_date,
                                            c_lot_split_rec.inv_org_id
                                           );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Inventory Period '
                     || c_lot_split_rec.inv_org_id
                     || ' is not open for the given transaction date '
                     || REPLACE (c_lot_split_rec.transaction_date, ':', '');
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.inventory_item_id IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg := l_err_msg || '|' || 'Item Id Should not be null';
            ELSE
               BEGIN
                  SELECT DECODE (msi.lot_control_code, 2, 'TRUE', 'FALSE'),
                         DECODE (msi.serial_number_control_code,
                                 2, 'TRUE',
                                 5, 'TRUE',
                                 'FALSE'
                                )
                    INTO l_lot_control_code,
                         l_serial_number_control_code
                    FROM mtl_system_items_b msi
                   WHERE 1 = 1
                     AND msi.inventory_item_id =
                                             c_lot_split_rec.inventory_item_id
                     AND msi.organization_id = c_lot_split_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_record_status := 'E';
                     l_err_msg :=
                           l_err_msg
                        || '|'
                        || 'Inventory Item Id'
                        || c_lot_split_rec.inventory_item_id
                        || ' is Not Valid';
               END;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.lot_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Parent/Source LotNumber Should not be null';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM mtl_lot_numbers
                WHERE inventory_item_id = c_lot_split_rec.inventory_item_id
                  AND lot_number = c_lot_split_rec.lot_number
                  AND organization_id = c_lot_split_rec.inv_org_id;

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Source LotNumber '
                     || c_lot_split_rec.lot_number
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.source_lpn_id IS NOT NULL
            THEN
               l_src_lpn_context := NULL;
               l_src_lpn_subinventory_code := NULL;
               l_src_lpn_locator_id := NULL;

               BEGIN
                  SELECT DISTINCT lpn_context,
                                  subinventory_code,
                                  locator_id
                             INTO l_src_lpn_context,
                                  l_src_lpn_subinventory_code,
                                  l_src_lpn_locator_id
                             FROM wms_license_plate_numbers wlpn,
                                  wms_lpn_contents wlc
                            WHERE wlpn.lpn_id = c_lot_split_rec.source_lpn_id
                              AND wlpn.lpn_context IN (1)
                              AND wlpn.organization_id =
                                                    c_lot_split_rec.inv_org_id
                              AND wlc.inventory_item_id =
                                             c_lot_split_rec.inventory_item_id
                              AND wlpn.lpn_id = wlc.parent_lpn_id
                              AND wlc.lot_number = c_lot_split_rec.lot_number
                              AND wlc.organization_id = wlpn.organization_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_src_lpn_context := NULL;
               END;

               IF l_src_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Source Lpn '
                     || c_lot_split_rec.source_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.source_sub_inventory IS NOT NULL
            THEN
               l_check := 0;
               l_check :=
                  xxprop_common_util_pkg.validate_subinventory
                                       (c_lot_split_rec.source_sub_inventory,
                                        c_lot_split_rec.inv_org_id
                                       );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Source SubInventory '
                     || c_lot_split_rec.source_sub_inventory
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.source_locator IS NOT NULL
            THEN
               l_src_locator_id := 0;
               l_src_locator_id :=
                  xxprop_common_util_pkg.validate_locator
                                       (c_lot_split_rec.source_locator,
                                        c_lot_split_rec.source_sub_inventory,
                                        c_lot_split_rec.inv_org_id
                                       );

               IF l_src_locator_id <= 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Source Locator '
                     || c_lot_split_rec.source_locator
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         IF c_lot_split_rec.source_lpn_id IS NOT NULL
         THEN
            IF NVL (l_src_lpn_subinventory_code,
                    NVL (c_lot_split_rec.source_sub_inventory, 'XXXX')
                   ) <>
                  NVL (c_lot_split_rec.source_sub_inventory,
                       NVL (l_src_lpn_subinventory_code, 'XXXX')
                      )
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Source SubInventory '
                  || c_lot_split_rec.source_sub_inventory
                  || ' is not Matching with LPN Subinventory '
                  || l_src_lpn_subinventory_code;
            END IF;

            IF NVL (l_src_lpn_locator_id, NVL (l_src_locator_id, -1)) <>
                         NVL (l_src_locator_id, NVL (l_src_lpn_locator_id, -1))
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Source Locator '
                  || c_lot_split_rec.source_locator
                  || ' is not Matching with LPN Locator ';
            END IF;
         END IF;

         BEGIN
            IF c_lot_split_rec.dest_lot_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Child/Destination LotNumber Should not be null';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM mtl_lot_numbers
                WHERE 1 = 1
                  --inventory_item_id = c_lot_split_rec.inventory_item_id
                  AND lot_number = c_lot_split_rec.dest_lot_number
                  AND organization_id = c_lot_split_rec.inv_org_id;

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Child/Destination LotNumber '
                     || c_lot_split_rec.lot_number
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.dest_lpn_id IS NOT NULL
            THEN
               l_dest_lpn_context := NULL;
               l_dest_lpn_subinventory_code := NULL;
               l_dest_lpn_locator_id := NULL;

               BEGIN
                  SELECT DISTINCT lpn_context,
                                  subinventory_code,
                                  locator_id
                             INTO l_dest_lpn_context,
                                  l_dest_lpn_subinventory_code,
                                  l_dest_lpn_locator_id
                             FROM wms_license_plate_numbers wlpn
                            WHERE wlpn.lpn_id = c_lot_split_rec.dest_lpn_id
                              AND wlpn.lpn_context IN (1, 5)
                              AND wlpn.organization_id =
                                                    c_lot_split_rec.inv_org_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_dest_lpn_context := NULL;
               END;

               IF l_dest_lpn_context IS NULL
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Parent/Dest Lpn '
                     || c_lot_split_rec.dest_lpn_id
                     || ' is Not Valid or not in Status like Resides in Inventory or Pre-generated Status';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.dest_sub_inventory IS NOT NULL
            THEN
               l_check := 0;
               l_check :=
                  xxprop_common_util_pkg.validate_subinventory
                                         (c_lot_split_rec.dest_sub_inventory,
                                          c_lot_split_rec.inv_org_id
                                         );

               IF l_check = 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Dest SubInventory '
                     || c_lot_split_rec.dest_sub_inventory
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         BEGIN
            IF c_lot_split_rec.dest_locator IS NOT NULL
            THEN
               l_dest_locator_id := 0;
               l_dest_locator_id :=
                  xxprop_common_util_pkg.validate_locator
                                         (c_lot_split_rec.dest_locator,
                                          c_lot_split_rec.dest_sub_inventory,
                                          c_lot_split_rec.inv_org_id
                                         );

               IF l_dest_locator_id <= 0
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Dest Locator '
                     || c_lot_split_rec.dest_locator
                     || ' is not Valid ';
               END IF;
            END IF;
         END;

         IF c_lot_split_rec.dest_lpn_id IS NOT NULL
         THEN
            IF NVL (l_dest_lpn_subinventory_code,
                    NVL (c_lot_split_rec.dest_sub_inventory, 'XXXX')
                   ) <>
                  NVL (c_lot_split_rec.dest_sub_inventory,
                       NVL (l_dest_lpn_subinventory_code, 'XXXX')
                      )
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Dest SubInventory '
                  || c_lot_split_rec.dest_sub_inventory
                  || ' is not Matching with LPN Subinventory '
                  || l_dest_lpn_subinventory_code;
            END IF;

            IF NVL (l_dest_lpn_locator_id, NVL (l_dest_locator_id, -1)) <>
                       NVL (l_dest_locator_id, NVL (l_dest_lpn_locator_id, -1))
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Dest Locator '
                  || c_lot_split_rec.dest_locator
                  || ' is not Matching with LPN Locator ';
            END IF;
         END IF;

         /*IF     l_serial_number_control_code = 'TRUE'
            AND c_lot_split_rec.inventory_item_id IS NOT NULL
         THEN
            IF c_lot_split_rec.serial_number IS NULL
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Serial number is null but item is Serial Control, Please pass Serial number.';
            ELSE
               l_check := 0;

               SELECT COUNT (*)
                 INTO l_check
                 FROM mtl_serial_numbers msn
                WHERE inventory_item_id = c_lot_split_rec.inventory_item_id
                  AND owning_organization_id = c_lot_split_rec.inv_org_id
                  AND serial_number = c_lot_split_rec.serial_number
                  AND lpn_id = NVL (c_lot_split_rec.source_lpn_id, lpn_id);

               IF l_check = 0                                             -- 2
               THEN
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Serial Number Not Valid or not Residing into the Parent/Source Lpn';
               END IF;
            END IF;
         END IF;*/
         BEGIN
            IF NVL (c_lot_split_rec.quantity, 0) = 0
            THEN
               l_record_status := 'E';
               l_err_msg :=
                      l_err_msg || '|' || 'Quantity Should be greater than 0';
            ELSE
               BEGIN
                  l_unpack_item_qty_val :=
                     inv_txn_validations.get_immediate_lpn_item_qty
                        (p_lpn_id                       => NULL,
                         p_organization_id              => c_lot_split_rec.inv_org_id,
                         p_source_type_id               => -9999,
                         p_inventory_item_id            => c_lot_split_rec.inventory_item_id,
                         p_revision                     => NULL,
                         p_locator_id                   => NVL
                                                              (l_src_lpn_locator_id,
                                                               l_src_locator_id
                                                              ),
                         p_subinventory_code            => NVL
                                                              (l_src_lpn_subinventory_code,
                                                               c_lot_split_rec.source_sub_inventory
                                                              ),
                         p_lot_number                   => c_lot_split_rec.lot_number,
                         p_is_revision_control          => 'FALSE',
                         p_is_serial_control            => l_serial_number_control_code,
                         p_is_lot_control               => 'TRUE',
                         x_transactable_qty             => l_transactable_qty,
                         x_qoh                          => l_qoh,
                         x_lpn_onhand                   => l_lpn_onhand,
                         x_return_msg                   => l_api_return_msg,
                         p_is_clear_quantity_cache      => 'TRUE'
                        );
               END;

               DBMS_OUTPUT.put_line (   'l_transactable_qty-'
                                     || l_transactable_qty
                                    );
               DBMS_OUTPUT.put_line (' l_qoh=' || l_qoh);
               DBMS_OUTPUT.put_line (' l_lpn_onhand=' || l_lpn_onhand);

               IF l_unpack_item_qty_val = 'Y'
               THEN
                  IF c_lot_split_rec.quantity > l_qoh    --l_transactable_qty
                  THEN
                     l_record_status := 'E';
                     l_err_msg :=
                           l_err_msg
                        || '|'
                        || 'Quantity greater than the available quantity ';
                  END IF;
               ELSE
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Error While calling getting available quantity API-'
                     || l_api_return_msg;
               END IF;
            END IF;

            BEGIN
               SELECT msi.secondary_uom_code
                 INTO l_sec_uom_code
                 FROM apps.mtl_system_items_b msi
                WHERE 1 = 1
                  AND msi.secondary_uom_code IS NOT NULL
                  AND msi.tracking_quantity_ind = 'PS'
                  AND msi.dual_uom_control = 2
                  AND msi.organization_id = c_lot_split_rec.inv_org_id
                  AND msi.inventory_item_id =
                                             c_lot_split_rec.inventory_item_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_sec_uom_code := NULL;
            END;
         END;

         IF l_sec_uom_code IS NOT NULL
         THEN
            l_sec_qty :=
               inv_convert.inv_um_convert
                              (item_id              => c_lot_split_rec.inventory_item_id,
                               lot_number           => c_lot_split_rec.lot_number,
                               organization_id      => c_lot_split_rec.inv_org_id,
                               PRECISION            => NULL,
                               from_quantity        => c_lot_split_rec.quantity,
                               from_unit            => c_lot_split_rec.uom_code,
                               to_unit              => l_sec_uom_code,
                               from_name            => NULL,
                               to_name              => NULL
                              );

            IF l_sec_qty = -99999
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Error while pulling the Secondory Qty inv_convert.inv_um_convert Error ';
            END IF;
         END IF;

         UPDATE xxalg_lpn_lot_split_merge_gt
            SET resp_application_id = l_allplication_id,
                transaction_action_id = 40,
                transaction_type_id = 82,
                transaction_source_type_id = 13,
                secondary_uom_code = l_sec_uom_code,
                secondary_quantity = l_sec_qty,
                source_sub_inventory =
                   NVL (l_src_lpn_subinventory_code,
                        c_lot_split_rec.source_sub_inventory
                       ),
                source_locator_id =
                                  NVL (l_src_lpn_locator_id, l_src_locator_id),
                dest_sub_inventory =
                   NVL (l_dest_lpn_subinventory_code,
                        c_lot_split_rec.dest_sub_inventory
                       ),
                dest_locator_id =
                                NVL (l_dest_lpn_locator_id, l_dest_locator_id),
                record_status = l_record_status,
                record_message = l_err_msg
          WHERE record_num = c_lot_split_rec.record_num
            AND record_grp_id = p_group_id;

         xxprop_common_util_pkg.trace_log
                          (p_module            =>    g_package_name
                                                  || '.'
                                                  || l_procedure_name,
                           p_message_text      =>    'Validation Record Message- '
                                                  || l_err_msg,
                           p_payload           => NULL
                          );
      END LOOP;

      BEGIN
         SELECT COUNT (*)
           INTO l_check
           FROM xxalg_lpn_lot_split_merge_gt
          WHERE record_grp_id = p_group_id AND record_status = 'V';
      END;

      IF l_check > 0
      THEN
         x_return_status := 'S';
      ELSE
         x_return_status := 'E';
      END IF;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         l_err_msg := 'Exception in validate_lot_split_data:-' || SQLERRM;
         x_return_msg := l_err_msg;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => l_err_msg,
                                           p_payload           => NULL
                                          );
   END validate_lot_split_data;
   PROCEDURE lpn_merge_interface (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name   VARCHAR2 (200)  := 'LPN_MERGE_INTERFACE';
      l_transaction_id   NUMBER;
      l_err_msg          VARCHAR2 (1000);
      l_record_status    VARCHAR2 (10);
      l_trx_hdr_id       NUMBER;
      l_mmt_api_return   NUMBER;
      l_mmt_trx_tmp_id   NUMBER;
      l_proc_msg         VARCHAR2 (4000);
      l_trx_api_return   NUMBER;
      l_check            NUMBER;

      --l_scrap_acct_chk   VARCHAR2 (10);
      CURSOR c_lpn_merge_cur
      IS
         SELECT   *
             FROM xxalg_lpn_lot_split_merge_gt
            WHERE record_grp_id = p_group_id AND record_status = 'V'
         ORDER BY mobile_transaction_id, transaction_date ASC;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      COMMIT;

      FOR c_lpn_merge_rec IN c_lpn_merge_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := NULL;
         l_proc_msg := NULL;
         l_mmt_trx_tmp_id := NULL;
         l_trx_api_return := NULL;
         l_mmt_api_return := NULL;

         SELECT apps.mtl_material_transactions_s.NEXTVAL
           INTO l_trx_hdr_id
           FROM DUAL;

         l_mmt_api_return :=
            inv_trx_util_pub.insert_line_trx
               (p_trx_hdr_id             => l_trx_hdr_id,
                p_item_id                => -1,
                p_revision               => NULL,
                p_org_id                 => c_lpn_merge_rec.inv_org_id,
                p_trx_action_id          => c_lpn_merge_rec.transaction_action_id,
                p_subinv_code            => c_lpn_merge_rec.source_sub_inventory,
                p_tosubinv_code          => NULL,
                p_locator_id             => c_lpn_merge_rec.source_locator_id,
                p_tolocator_id           => NULL,
                p_xfr_org_id             => NULL,
                p_trx_type_id            => c_lpn_merge_rec.transaction_type_id,
                p_trx_src_type_id        => c_lpn_merge_rec.transaction_source_type_id,
                p_trx_qty                => 1,
                p_pri_qty                => 1,
                p_uom                    => 'Ea',
                p_date                   => c_lpn_merge_rec.transaction_date,
                p_reason_id              => NULL,
                p_user_id                => c_lpn_merge_rec.user_id,
                p_frt_code               => NULL,
                p_ship_num               => NULL,
                p_dist_id                => NULL,
                p_way_bill               => NULL,
                p_exp_arr                => NULL,
                p_cost_group             => NULL,
                p_from_lpn_id            => NULL,
                p_cnt_lpn_id             => c_lpn_merge_rec.dest_lpn_id,
                p_xfr_lpn_id             => c_lpn_merge_rec.source_lpn_id,
                p_trx_src_id             => NULL,
                p_xfr_cost_group         => NULL,
                p_completion_trx_id      => NULL,
                p_flow_schedule          => NULL,
                p_trx_cost               => NULL,
                p_project_id             => NULL,
                p_task_id                => NULL,
                x_trx_tmp_id             => l_mmt_trx_tmp_id,
                x_proc_msg               => l_proc_msg
               );
         xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      =>    'l_mmt_api_return-'
                                                          || l_mmt_api_return
                                                          || '  l_mmt_trx_tmp_id-'
                                                          || l_mmt_trx_tmp_id
                                                          || '  l_mmt_proc_msg-'
                                                          || l_proc_msg,
                                   p_payload           => NULL
                                  );

         IF l_mmt_api_return = 0
         THEN
            l_proc_msg := NULL;
            l_trx_api_return :=
               inv_lpn_trx_pub.process_lpn_trx
                                            (p_trx_hdr_id              => l_trx_hdr_id,
                                             p_commit                  => fnd_api.g_false,
                                             x_proc_msg                => l_proc_msg,
                                             p_proc_mode               => NULL,
                                             p_process_trx             => fnd_api.g_true,
                                             p_atomic                  => fnd_api.g_false,
                                             p_business_flow_code      => 20
                                            );

            IF l_trx_api_return = 0
            THEN
               BEGIN
                  SELECT COUNT (*)
                    INTO l_check
                    FROM mtl_material_transactions
                   WHERE transaction_set_id = l_trx_hdr_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_check := 0;
               END;

               DBMS_OUTPUT.put_line (   ' l_mmt_trx_tmp_id-'
                                     || l_mmt_trx_tmp_id
                                     || '  l_trx_hdr_id'
                                     || l_trx_hdr_id
                                    );

               IF l_check > 0
               THEN
                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'S',
                         record_message = NULL,
                         transaction_id = l_trx_hdr_id
                   WHERE record_num = c_lpn_merge_rec.record_num
                     AND record_grp_id = p_group_id;

                  COMMIT;
               ELSE
                  ROLLBACK;
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Error While Process Lpn Transaction, Transaction Set Id not Created-'
                     || l_proc_msg;

                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'E',
                         record_message = l_err_msg
                   WHERE record_num = c_lpn_merge_rec.record_num
                     AND record_grp_id = p_group_id;

                  COMMIT;
                  xxprop_common_util_pkg.trace_log
                     (p_module            =>    g_package_name
                                             || '.'
                                             || l_procedure_name,
                      p_message_text      =>    'Error While Process Lpn Transaction, Transaction Set Id not Created-'
                                             || l_proc_msg,
                      p_payload           => NULL
                     );
               END IF;
            ELSE
               ROLLBACK;
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Error While Process Lpn Transaction-'
                  || l_proc_msg;

               UPDATE xxalg_lpn_lot_split_merge_gt
                  SET record_status = 'E',
                      record_message = l_err_msg
                WHERE record_num = c_lpn_merge_rec.record_num
                  AND record_grp_id = p_group_id;

               COMMIT;
               xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      =>    'Error While Process Lpn Transaction-'
                                          || l_proc_msg,
                   p_payload           => NULL
                  );
            END IF;
         ELSE
            ROLLBACK;
            l_record_status := 'E';
            l_err_msg :=
                  l_err_msg
               || '|'
               || 'Error While Inserting MMT api-'
               || l_proc_msg;

            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = l_err_msg
             WHERE record_num = c_lpn_merge_rec.record_num
               AND record_grp_id = p_group_id;

            COMMIT;
            xxprop_common_util_pkg.trace_log
                       (p_module            =>    g_package_name
                                               || '.'
                                               || l_procedure_name,
                        p_message_text      =>    'Error While Inserting MMT api-'
                                               || l_proc_msg,
                        p_payload           => NULL
                       );
         END IF;
      END LOOP;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_msg := 'Exception in lpn_merge_interface:-' || SQLERRM;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => x_return_msg,
                                           p_payload           => NULL
                                          );
   END lpn_merge_interface;

   PROCEDURE lot_merge_interface (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name       VARCHAR2 (200)  := 'LOT_MERGE_INTERFACE';
      l_transaction_id       NUMBER;
      l_err_msg              VARCHAR2 (1000);
      l_record_status        VARCHAR2 (10);
      l_trx_hdr_id           NUMBER;
      l_proc_msg             VARCHAR2 (4000);
      l_trx_api_return       NUMBER;
      l_check                NUMBER;
      l_parent_id            NUMBER;
      l_txn_if_id1           NUMBER;
      l_txn_if_id2           NUMBER;
      l_retval               NUMBER;
      l_api_return_status    VARCHAR2 (100);
      l_api_msg_cnt          NUMBER;
      l_api_msg_data         VARCHAR2 (500);
      l_api_trans_count      VARCHAR2 (100);
      l_transaction_set_id   NUMBER;
      l_txn_if_id3           NUMBER;

      --l_scrap_acct_chk   VARCHAR2 (10);
      CURSOR c_lot_merge_cur
      IS
         SELECT   *
             FROM xxalg_lpn_lot_split_merge_gt
            WHERE record_grp_id = p_group_id AND record_status = 'V'
         ORDER BY mobile_transaction_id, transaction_date ASC;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      COMMIT;

      FOR c_lot_merge_rec IN c_lot_merge_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := 'I';
         l_proc_msg := NULL;
         l_trx_api_return := NULL;
         l_parent_id := NULL;
         l_txn_if_id1 := NULL;
         l_txn_if_id2 := NULL;
         l_txn_if_id3 := NULL;
         l_retval := NULL;
         l_api_return_status := NULL;
         l_api_msg_cnt := NULL;
         l_api_msg_data := NULL;
         l_api_trans_count := NULL;
         l_transaction_set_id := NULL;

         SELECT apps.mtl_material_transactions_s.NEXTVAL
           INTO l_trx_hdr_id
           FROM DUAL;

         SELECT apps.mtl_material_transactions_s.NEXTVAL
           INTO l_txn_if_id1
           FROM DUAL;

         l_parent_id := l_txn_if_id1;

         BEGIN
            INSERT INTO mtl_transactions_interface
                        (transaction_interface_id, transaction_header_id,
                         source_code, source_line_id, source_header_id,
                         process_flag, transaction_mode, lock_flag,
                         last_update_date, last_updated_by, creation_date,
                         created_by,
                         organization_id,
                         transaction_quantity, transaction_uom,
                         transaction_date,
                         inventory_item_id, revision,
                         subinventory_code,
                         locator_id,
                         transaction_type_id,
                         transaction_source_type_id,
                         transaction_action_id,
                         primary_quantity, parent_id,
                         distribution_account_id, transaction_batch_id,
                         transaction_batch_seq, lpn_id, transfer_lpn_id,cost_group_id
                        )
                 VALUES (l_txn_if_id1, l_trx_hdr_id,
                         'INV', -1, -1,
                         1, 3, 2,
                         SYSDATE, c_lot_merge_rec.user_id, SYSDATE,
                         c_lot_merge_rec.user_id,
                         c_lot_merge_rec.inv_org_id,
                         c_lot_merge_rec.quantity*2, c_lot_merge_rec.uom_code,
                         c_lot_merge_rec.transaction_date,
                         c_lot_merge_rec.inventory_item_id, NULL,
                         c_lot_merge_rec.dest_sub_inventory,
                         c_lot_merge_rec.dest_locator_id,
                         c_lot_merge_rec.transaction_type_id,
                         c_lot_merge_rec.transaction_source_type_id,
                         c_lot_merge_rec.transaction_action_id,
                         c_lot_merge_rec.quantity*2, l_parent_id,
                         NULL, l_trx_hdr_id,
                         1, NULL,             --c_lot_merge_rec.source_lpn_id,
                                 c_lot_merge_rec.dest_lpn_id,42520
                        );

--Insert MTLI corresponding to the resultant MTI record
            INSERT INTO mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code, source_line_id,
                         process_flag, last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         primary_quantity
                        )
                 VALUES (l_txn_if_id1               --transaction_interface_id
                                     ,
                         'INV'                                   --Source_Code
                              , -1                            --Source_Line_Id
                                  ,
                         'Y'                                    --Process_Flag
                            , SYSDATE                       --Last_Update_Date
                                     ,
                         c_lot_merge_rec.user_id             --Last_Updated_by
                                                ,
                         SYSDATE                               --Creation_date
                                ,
                         c_lot_merge_rec.user_id                  --Created_By
                                                ,
                         c_lot_merge_rec.dest_lot_number          --Lot_Number
                                                        ,
                         NULL                            --Lot_Expiration_Date
                             ,
                         c_lot_merge_rec.quantity*2       --transaction_quantity
                                                 ,
                         c_lot_merge_rec.quantity*2           --primary_quantity
                        );

            SELECT apps.mtl_material_transactions_s.NEXTVAL
              INTO l_txn_if_id2
              FROM DUAL;

--Populate the MTI record for Source record-1
            INSERT INTO mtl_transactions_interface
                        (transaction_interface_id, transaction_header_id,
                         source_code, source_line_id, source_header_id,
                         process_flag, transaction_mode, lock_flag,
                         inventory_item_id, revision,
                         organization_id,
                         subinventory_code,
                         locator_id,
                         transaction_type_id,
                         transaction_source_type_id,
                         transaction_action_id,
                         transaction_quantity,
                         transaction_uom,
                         primary_quantity,
                         transaction_date, last_update_date,
                         last_updated_by, creation_date,
                         created_by, distribution_account_id, parent_id,
                         transaction_batch_id, transaction_batch_seq, lpn_id,
                         transfer_lpn_id,cost_group_id
                        )
                 VALUES (l_txn_if_id2,                 --transaction_header_id
                                      l_trx_hdr_id, --transaction_interface_id
                         'INV',                                  --source_code
                               -1,                          --source_header_id
                                  -1,                         --source_line_id
                         1,                                     --process_flag
                           3,                               --transaction_mode
                             2,                                    --lock_flag
                         c_lot_merge_rec.inventory_item_id,
                                                           --inventory_item_id
                         NULL,                                      --revision
                         c_lot_merge_rec.inv_org_id,         --organization_id
                         c_lot_merge_rec.dest_sub_inventory,
                         --subinventory_code
                         c_lot_merge_rec.dest_locator_id,       --locator_id
                         c_lot_merge_rec.transaction_type_id,
                         --transaction_type_id
                         c_lot_merge_rec.transaction_source_type_id,
                         --transaction_source_type_id
                         c_lot_merge_rec.transaction_action_id,
                         
                         --transaction_action_id
                         (c_lot_merge_rec.quantity
                         ) * (-1),                      --transaction_quantity
                         c_lot_merge_rec.uom_code,
                         
                         --transaction_uom
                         (c_lot_merge_rec.quantity) * (-1), --primary_quantity
                         c_lot_merge_rec.transaction_date,  --Transaction_Date
                                                          SYSDATE,
                         --Last_Update_Date
                         c_lot_merge_rec.user_id,            --Last_Updated_by
                                                 SYSDATE,      --Creation_Date
                         c_lot_merge_rec.user_id,                 --Created_by
                                                 NULL,
                                                      --distribution_account_id
                                                      l_parent_id, --parent_id
                         l_trx_hdr_id,                  --transaction_batch_id
                                      2,               --transaction_batch_seq
                                        c_lot_merge_rec.source_lpn_id,
                         --lpn_id (for source MTI)
                         NULL                  ,42520
                        );

--Insert MTLI corresponding to the Source record-1
            INSERT INTO mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code, source_line_id,
                         process_flag, last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         primary_quantity
                        )
                 VALUES (l_txn_if_id2               --transaction_interface_id
                                     ,
                         'INV'                                   --Source_Code
                              , -1                            --Source_Line_Id
                                  ,
                         'Y'                                    --Process_Flag
                            , SYSDATE                       --Last_Update_Date
                                     ,
                         c_lot_merge_rec.user_id             --Last_Updated_by
                                                ,
                         SYSDATE                               --Creation_date
                                ,
                         c_lot_merge_rec.user_id                  --Created_By
                                                ,
                         c_lot_merge_rec.dest_lot_number               --Lot_Number
                                                   ,
                         NULL                            --Lot_Expiration_Date
                             ,
                         (c_lot_merge_rec.quantity) * (-1),
                         (c_lot_merge_rec.quantity
                         ) * (-1)
                        );

            SELECT apps.mtl_material_transactions_s.NEXTVAL
              INTO l_txn_if_id3
              FROM DUAL;

            INSERT INTO mtl_transactions_interface
                        (transaction_interface_id, transaction_header_id,
                         source_code, source_line_id, source_header_id,
                         process_flag, transaction_mode, lock_flag,
                         inventory_item_id, revision,
                         organization_id,
                         subinventory_code,
                         locator_id,
                         transaction_type_id,
                         transaction_source_type_id,
                         transaction_action_id,
                         transaction_quantity,
                         transaction_uom,
                         primary_quantity,
                         transaction_date, last_update_date,
                         last_updated_by, creation_date,
                         created_by, distribution_account_id, parent_id,
                         transaction_batch_id, transaction_batch_seq, lpn_id,
                         transfer_lpn_id,cost_group_id
                        )
                 VALUES (l_txn_if_id3,                 --transaction_header_id
                                      l_trx_hdr_id, --transaction_interface_id
                         'INV',                                  --source_code
                               -1,                          --source_header_id
                                  -1,                         --source_line_id
                         1,                                     --process_flag
                           3,                               --transaction_mode
                             2,                                    --lock_flag
                         c_lot_merge_rec.inventory_item_id,
                                                           --inventory_item_id
                         NULL,                                      --revision
                         c_lot_merge_rec.inv_org_id,         --organization_id
                         c_lot_merge_rec.source_sub_inventory,
                         --subinventory_code
                         c_lot_merge_rec.source_locator_id,       --locator_id
                         c_lot_merge_rec.transaction_type_id,
                         --transaction_type_id
                         c_lot_merge_rec.transaction_source_type_id,
                         --transaction_source_type_id
                         c_lot_merge_rec.transaction_action_id,
                         
                         --transaction_action_id
                         (c_lot_merge_rec.quantity
                         ) * (-1),                      --transaction_quantity
                         c_lot_merge_rec.uom_code,
                         
                         --transaction_uom
                         (c_lot_merge_rec.quantity) * (-1), --primary_quantity
                         c_lot_merge_rec.transaction_date,  --Transaction_Date
                                                          SYSDATE,
                         --Last_Update_Date
                         c_lot_merge_rec.user_id,            --Last_Updated_by
                                                 SYSDATE,      --Creation_Date
                         c_lot_merge_rec.user_id,                 --Created_by
                                                 NULL,
                                                      --distribution_account_id
                                                      l_parent_id, --parent_id
                         l_trx_hdr_id,                  --transaction_batch_id
                                      3,               --transaction_batch_seq
                                        c_lot_merge_rec.source_lpn_id,
                         --lpn_id (for source MTI)
                         NULL ,42520
                        );

--Insert MTLI corresponding to the Source record-1
            INSERT INTO mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code, source_line_id,
                         process_flag, last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         primary_quantity
                        )
                 VALUES (l_txn_if_id3               --transaction_interface_id
                                     ,
                         'INV'                                   --Source_Code
                              , -1                            --Source_Line_Id
                                  ,
                         'Y'                                    --Process_Flag
                            , SYSDATE                       --Last_Update_Date
                                     ,
                         c_lot_merge_rec.user_id             --Last_Updated_by
                                                ,
                         SYSDATE                               --Creation_date
                                ,
                         c_lot_merge_rec.user_id                  --Created_By
                                                ,
                         c_lot_merge_rec.lot_number               --Lot_Number
                                                   ,
                         NULL                            --Lot_Expiration_Date
                             ,
                         (c_lot_merge_rec.quantity) * (-1),
                         (c_lot_merge_rec.quantity
                         ) * (-1)
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Error while inserting records into mtl_transactions_interface.'
                  || SQLERRM;
               xxprop_common_util_pkg.trace_log
                                               (p_module            =>    g_package_name
                                                                       || '.'
                                                                       || l_procedure_name,
                                                p_message_text      => l_err_msg,
                                                p_payload           => NULL
                                               );
         END;

         IF l_record_status <> 'E'
         THEN
            l_retval :=
               apps.inv_txn_manager_pub.process_transactions
                           (p_api_version           => 1.0,
                            p_init_msg_list         => fnd_api.g_false,
                            p_commit                => fnd_api.g_false,
                            p_validation_level      => fnd_api.g_valid_level_full,
                            x_return_status         => l_api_return_status,
                            x_msg_count             => l_api_msg_cnt,
                            x_msg_data              => l_api_msg_data,
                            x_trans_count           => l_api_trans_count,
                            p_table                 => 1,
                            p_header_id             => l_trx_hdr_id
                           );
            xxprop_common_util_pkg.trace_log
               (p_module            => g_package_name || '.'
                                       || l_procedure_name,
                p_message_text      =>    'inv_txn_manager_pub.process_transactions API Status-'
                                       || l_api_return_status
                                       || '  API Message:-'
                                       || l_api_msg_data,
                p_payload           => NULL
               );

            IF l_retval = 0 AND l_api_return_status = 'S'
            THEN
               BEGIN
                  SELECT MAX (transaction_set_id)
                    INTO l_transaction_set_id
                    FROM mtl_material_transactions
                   WHERE transaction_set_id = l_trx_hdr_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_transaction_set_id := NULL;
               END;

               IF l_transaction_set_id IS NOT NULL
               THEN
                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'S',
                         record_message = NULL,
                         transaction_id = l_trx_hdr_id
                   WHERE record_num = c_lot_merge_rec.record_num
                     AND record_grp_id = p_group_id;

                  --COMMIT;
                  xxprop_common_util_pkg.trace_log
                     (p_module            =>    g_package_name
                                             || '.'
                                             || l_procedure_name,
                      p_message_text      =>    'Lot Split Transaction Completed with transaction_set_id-'
                                             || l_transaction_set_id,
                      p_payload           => NULL
                     );
               ELSE
                  --ROLLBACK;
                  l_err_msg :=
                             'Error Packing:-TransactionSet ID not generated';

                  /*UPDATE xxalg_wip_mo_tran_gt
                     SET record_status = 'E',
                         record_message = record_message || '|' || l_err_msg
                   WHERE record_grp_id = g_record_id
                         AND record_num = p_record_num;*/
                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'E',
                         record_message = record_message || '|' || l_err_msg
                   WHERE record_num = c_lot_merge_rec.record_num
                     AND record_grp_id = p_group_id;

                  /*DELETE FROM mtl_transaction_lots_interface mtli
                        WHERE EXISTS (
                                 SELECT 1
                                   FROM mtl_transactions_interface mti
                                  WHERE mti.transaction_header_id =
                                                                  l_trx_hdr_id
                                    AND mtli.transaction_interface_id =
                                                  mti.transaction_interface_id);

                  DELETE FROM mtl_transactions_interface
                        WHERE transaction_header_id = l_trx_hdr_id;*/

                  --COMMIT;
                  xxprop_common_util_pkg.trace_log
                     (p_module            =>    g_package_name
                                             || '.'
                                             || l_procedure_name,
                      p_message_text      => 'Delete record from mtl_transactions_interface when l_transaction_set_id is null',
                      p_payload           => NULL
                     );
               END IF;
            ELSE
               BEGIN
                  SELECT 'Error Lot Merge:-' || error_explanation
                    INTO l_err_msg
                    FROM mtl_transactions_interface
                   WHERE transaction_header_id = l_trx_hdr_id
                     AND error_explanation IS NOT NULL
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_err_msg := NULL;
               END;

               --ROLLBACK;
               UPDATE xxalg_lpn_lot_split_merge_gt
                  SET record_status = 'E',
                      record_message = record_message || '|' || l_err_msg
                WHERE record_num = c_lot_merge_rec.record_num
                  AND record_grp_id = p_group_id;

               /*DELETE FROM mtl_transaction_lots_interface mtli
                     WHERE EXISTS (
                              SELECT 1
                                FROM mtl_transactions_interface mti
                               WHERE mti.transaction_header_id = l_trx_hdr_id
                                 AND mtli.transaction_interface_id =
                                                  mti.transaction_interface_id);

               DELETE FROM mtl_transactions_interface
                     WHERE transaction_header_id = l_trx_hdr_id;*/

               --COMMIT;
               xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      => 'Delete record from mtl_transactions_interface when API get error',
                   p_payload           => NULL
                  );
            END IF;
         ELSE
            --ROLLBACK;
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || '|' || l_err_msg
             WHERE record_num = c_lot_merge_rec.record_num
               AND record_grp_id = p_group_id;

            /*DELETE FROM mtl_transaction_lots_interface mtli
                  WHERE EXISTS (
                           SELECT 1
                             FROM mtl_transactions_interface mti
                            WHERE mti.transaction_header_id = l_trx_hdr_id
                              AND mtli.transaction_interface_id =
                                                  mti.transaction_interface_id);

            DELETE FROM mtl_transactions_interface
                  WHERE transaction_header_id = l_trx_hdr_id;*/

            --COMMIT;
            xxprop_common_util_pkg.trace_log
               (p_module            => g_package_name || '.'
                                       || l_procedure_name,
                p_message_text      =>    'Error while while inserting mtl_transactions_interface='
                                       || l_err_msg,
                p_payload           => NULL
               );
         END IF;
      END LOOP;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_msg := 'Exception in lot_merge_interface:-' || SQLERRM;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => x_return_msg,
                                           p_payload           => NULL
                                          );
   END lot_merge_interface;
   PROCEDURE lot_split_interface (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name       VARCHAR2 (200)  := 'LOT_split_INTERFACE';
      l_transaction_id       NUMBER;
      l_err_msg              VARCHAR2 (1000);
      l_record_status        VARCHAR2 (10);
      l_trx_hdr_id           NUMBER;
      l_proc_msg             VARCHAR2 (4000);
      l_trx_api_return       NUMBER;
      l_check                NUMBER;
      l_parent_id            NUMBER;
      l_txn_if_id1           NUMBER;
      l_txn_if_id2           NUMBER;
      l_retval               NUMBER;
      l_api_return_status    VARCHAR2 (100);
      l_api_msg_cnt          NUMBER;
      l_api_msg_data         VARCHAR2 (500);
      l_api_trans_count      VARCHAR2 (100);
      l_transaction_set_id   NUMBER;
      l_txn_if_id3           NUMBER;

      --l_scrap_acct_chk   VARCHAR2 (10);
      CURSOR c_lot_split_cur
      IS
         SELECT   *
             FROM xxalg_lpn_lot_split_merge_gt
            WHERE record_grp_id = p_group_id AND record_status = 'V'
         ORDER BY mobile_transaction_id, transaction_date ASC;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      COMMIT;

      FOR c_lot_split_rec IN c_lot_split_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := 'I';
         l_proc_msg := NULL;
         l_trx_api_return := NULL;
         l_parent_id := NULL;
         l_txn_if_id1 := NULL;
         l_txn_if_id2 := NULL;
         l_txn_if_id3 := NULL;
         l_retval := NULL;
         l_api_return_status := NULL;
         l_api_msg_cnt := NULL;
         l_api_msg_data := NULL;
         l_api_trans_count := NULL;
         l_transaction_set_id := NULL;

         SELECT apps.mtl_material_transactions_s.NEXTVAL
           INTO l_trx_hdr_id
           FROM DUAL;

         SELECT apps.mtl_material_transactions_s.NEXTVAL
           INTO l_txn_if_id1
           FROM DUAL;

         l_parent_id := l_txn_if_id1;

         BEGIN
            INSERT INTO mtl_transactions_interface
                        (transaction_interface_id, transaction_header_id,
                         source_code, source_line_id, source_header_id,
                         process_flag, transaction_mode, lock_flag,
                         last_update_date, last_updated_by, creation_date,
                         created_by,
                         organization_id,
                         transaction_quantity, transaction_uom,
                         transaction_date,
                         inventory_item_id, revision,
                         subinventory_code,
                         locator_id,
                         transaction_type_id,
                         transaction_source_type_id,
                         transaction_action_id,
                         primary_quantity, parent_id,
                         distribution_account_id, transaction_batch_id,
                         transaction_batch_seq, lpn_id, transfer_lpn_id,cost_group_id
                        )
                 VALUES (l_txn_if_id1, l_trx_hdr_id,
                         'INV', -1, -1,
                         1, 3, 2,
                         SYSDATE, c_lot_split_rec.user_id, SYSDATE,
                         c_lot_split_rec.user_id,
                         c_lot_split_rec.inv_org_id,
                         c_lot_split_rec.quantity*2, c_lot_split_rec.uom_code,
                         c_lot_split_rec.transaction_date,
                         c_lot_split_rec.inventory_item_id, NULL,
                         c_lot_split_rec.dest_sub_inventory,
                         c_lot_split_rec.dest_locator_id,
                         c_lot_split_rec.transaction_type_id,
                         c_lot_split_rec.transaction_source_type_id,
                         c_lot_split_rec.transaction_action_id,
                         c_lot_split_rec.quantity*2, l_parent_id,
                         NULL, l_trx_hdr_id,
                         1, NULL,             --c_lot_split_rec.source_lpn_id,
                                 c_lot_split_rec.dest_lpn_id,42520
                        );

--Insert MTLI corresponding to the resultant MTI record
            INSERT INTO mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code, source_line_id,
                         process_flag, last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         primary_quantity
                        )
                 VALUES (l_txn_if_id1               --transaction_interface_id
                                     ,
                         'INV'                                   --Source_Code
                              , -1                            --Source_Line_Id
                                  ,
                         'Y'                                    --Process_Flag
                            , SYSDATE                       --Last_Update_Date
                                     ,
                         c_lot_split_rec.user_id             --Last_Updated_by
                                                ,
                         SYSDATE                               --Creation_date
                                ,
                         c_lot_split_rec.user_id                  --Created_By
                                                ,
                         c_lot_split_rec.dest_lot_number          --Lot_Number
                                                        ,
                         NULL                            --Lot_Expiration_Date
                             ,
                         c_lot_split_rec.quantity*2       --transaction_quantity
                                                 ,
                         c_lot_split_rec.quantity*2           --primary_quantity
                        );

            SELECT apps.mtl_material_transactions_s.NEXTVAL
              INTO l_txn_if_id2
              FROM DUAL;

--Populate the MTI record for Source record-1
            INSERT INTO mtl_transactions_interface
                        (transaction_interface_id, transaction_header_id,
                         source_code, source_line_id, source_header_id,
                         process_flag, transaction_mode, lock_flag,
                         inventory_item_id, revision,
                         organization_id,
                         subinventory_code,
                         locator_id,
                         transaction_type_id,
                         transaction_source_type_id,
                         transaction_action_id,
                         transaction_quantity,
                         transaction_uom,
                         primary_quantity,
                         transaction_date, last_update_date,
                         last_updated_by, creation_date,
                         created_by, distribution_account_id, parent_id,
                         transaction_batch_id, transaction_batch_seq, lpn_id,
                         transfer_lpn_id,cost_group_id
                        )
                 VALUES (l_txn_if_id2,                 --transaction_header_id
                                      l_trx_hdr_id, --transaction_interface_id
                         'INV',                                  --source_code
                               -1,                          --source_header_id
                                  -1,                         --source_line_id
                         1,                                     --process_flag
                           3,                               --transaction_mode
                             2,                                    --lock_flag
                         c_lot_split_rec.inventory_item_id,
                                                           --inventory_item_id
                         NULL,                                      --revision
                         c_lot_split_rec.inv_org_id,         --organization_id
                         c_lot_split_rec.dest_sub_inventory,
                         --subinventory_code
                         c_lot_split_rec.dest_locator_id,       --locator_id
                         c_lot_split_rec.transaction_type_id,
                         --transaction_type_id
                         c_lot_split_rec.transaction_source_type_id,
                         --transaction_source_type_id
                         c_lot_split_rec.transaction_action_id,
                         
                         --transaction_action_id
                         (c_lot_split_rec.quantity
                         ) * (-1),                      --transaction_quantity
                         c_lot_split_rec.uom_code,
                         
                         --transaction_uom
                         (c_lot_split_rec.quantity) * (-1), --primary_quantity
                         c_lot_split_rec.transaction_date,  --Transaction_Date
                                                          SYSDATE,
                         --Last_Update_Date
                         c_lot_split_rec.user_id,            --Last_Updated_by
                                                 SYSDATE,      --Creation_Date
                         c_lot_split_rec.user_id,                 --Created_by
                                                 NULL,
                                                      --distribution_account_id
                                                      l_parent_id, --parent_id
                         l_trx_hdr_id,                  --transaction_batch_id
                                      2,               --transaction_batch_seq
                                        c_lot_split_rec.source_lpn_id,
                         --lpn_id (for source MTI)
                         NULL                  ,42520
                        );

--Insert MTLI corresponding to the Source record-1
            INSERT INTO mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code, source_line_id,
                         process_flag, last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         primary_quantity
                        )
                 VALUES (l_txn_if_id2               --transaction_interface_id
                                     ,
                         'INV'                                   --Source_Code
                              , -1                            --Source_Line_Id
                                  ,
                         'Y'                                    --Process_Flag
                            , SYSDATE                       --Last_Update_Date
                                     ,
                         c_lot_split_rec.user_id             --Last_Updated_by
                                                ,
                         SYSDATE                               --Creation_date
                                ,
                         c_lot_split_rec.user_id                  --Created_By
                                                ,
                         c_lot_split_rec.dest_lot_number               --Lot_Number
                                                   ,
                         NULL                            --Lot_Expiration_Date
                             ,
                         (c_lot_split_rec.quantity) * (-1),
                         (c_lot_split_rec.quantity
                         ) * (-1)
                        );

            SELECT apps.mtl_material_transactions_s.NEXTVAL
              INTO l_txn_if_id3
              FROM DUAL;

            INSERT INTO mtl_transactions_interface
                        (transaction_interface_id, transaction_header_id,
                         source_code, source_line_id, source_header_id,
                         process_flag, transaction_mode, lock_flag,
                         inventory_item_id, revision,
                         organization_id,
                         subinventory_code,
                         locator_id,
                         transaction_type_id,
                         transaction_source_type_id,
                         transaction_action_id,
                         transaction_quantity,
                         transaction_uom,
                         primary_quantity,
                         transaction_date, last_update_date,
                         last_updated_by, creation_date,
                         created_by, distribution_account_id, parent_id,
                         transaction_batch_id, transaction_batch_seq, lpn_id,
                         transfer_lpn_id,cost_group_id
                        )
                 VALUES (l_txn_if_id3,                 --transaction_header_id
                                      l_trx_hdr_id, --transaction_interface_id
                         'INV',                                  --source_code
                               -1,                          --source_header_id
                                  -1,                         --source_line_id
                         1,                                     --process_flag
                           3,                               --transaction_mode
                             2,                                    --lock_flag
                         c_lot_split_rec.inventory_item_id,
                                                           --inventory_item_id
                         NULL,                                      --revision
                         c_lot_split_rec.inv_org_id,         --organization_id
                         c_lot_split_rec.source_sub_inventory,
                         --subinventory_code
                         c_lot_split_rec.source_locator_id,       --locator_id
                         c_lot_split_rec.transaction_type_id,
                         --transaction_type_id
                         c_lot_split_rec.transaction_source_type_id,
                         --transaction_source_type_id
                         c_lot_split_rec.transaction_action_id,
                         
                         --transaction_action_id
                         (c_lot_split_rec.quantity
                         ) * (-1),                      --transaction_quantity
                         c_lot_split_rec.uom_code,
                         
                         --transaction_uom
                         (c_lot_split_rec.quantity) * (-1), --primary_quantity
                         c_lot_split_rec.transaction_date,  --Transaction_Date
                                                          SYSDATE,
                         --Last_Update_Date
                         c_lot_split_rec.user_id,            --Last_Updated_by
                                                 SYSDATE,      --Creation_Date
                         c_lot_split_rec.user_id,                 --Created_by
                                                 NULL,
                                                      --distribution_account_id
                                                      l_parent_id, --parent_id
                         l_trx_hdr_id,                  --transaction_batch_id
                                      3,               --transaction_batch_seq
                                        c_lot_split_rec.source_lpn_id,
                         --lpn_id (for source MTI)
                         NULL ,42520
                        );

--Insert MTLI corresponding to the Source record-1
            INSERT INTO mtl_transaction_lots_interface
                        (transaction_interface_id,
                         source_code, source_line_id,
                         process_flag, last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         lot_number,
                         lot_expiration_date,
                         transaction_quantity,
                         primary_quantity
                        )
                 VALUES (l_txn_if_id3               --transaction_interface_id
                                     ,
                         'INV'                                   --Source_Code
                              , -1                            --Source_Line_Id
                                  ,
                         'Y'                                    --Process_Flag
                            , SYSDATE                       --Last_Update_Date
                                     ,
                         c_lot_split_rec.user_id             --Last_Updated_by
                                                ,
                         SYSDATE                               --Creation_date
                                ,
                         c_lot_split_rec.user_id                  --Created_By
                                                ,
                         c_lot_split_rec.lot_number               --Lot_Number
                                                   ,
                         NULL                            --Lot_Expiration_Date
                             ,
                         (c_lot_split_rec.quantity) * (-1),
                         (c_lot_split_rec.quantity
                         ) * (-1)
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Error while inserting records into mtl_transactions_interface.'
                  || SQLERRM;
               xxprop_common_util_pkg.trace_log
                                               (p_module            =>    g_package_name
                                                                       || '.'
                                                                       || l_procedure_name,
                                                p_message_text      => l_err_msg,
                                                p_payload           => NULL
                                               );
         END;

         IF l_record_status <> 'E'
         THEN
            l_retval :=
               apps.inv_txn_manager_pub.process_transactions
                           (p_api_version           => 1.0,
                            p_init_msg_list         => fnd_api.g_false,
                            p_commit                => fnd_api.g_false,
                            p_validation_level      => fnd_api.g_valid_level_full,
                            x_return_status         => l_api_return_status,
                            x_msg_count             => l_api_msg_cnt,
                            x_msg_data              => l_api_msg_data,
                            x_trans_count           => l_api_trans_count,
                            p_table                 => 1,
                            p_header_id             => l_trx_hdr_id
                           );
            xxprop_common_util_pkg.trace_log
               (p_module            => g_package_name || '.'
                                       || l_procedure_name,
                p_message_text      =>    'inv_txn_manager_pub.process_transactions API Status-'
                                       || l_api_return_status
                                       || '  API Message:-'
                                       || l_api_msg_data,
                p_payload           => NULL
               );

            IF l_retval = 0 AND l_api_return_status = 'S'
            THEN
               BEGIN
                  SELECT MAX (transaction_set_id)
                    INTO l_transaction_set_id
                    FROM mtl_material_transactions
                   WHERE transaction_set_id = l_trx_hdr_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_transaction_set_id := NULL;
               END;

               IF l_transaction_set_id IS NOT NULL
               THEN
                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'S',
                         record_message = NULL,
                         transaction_id = l_trx_hdr_id
                   WHERE record_num = c_lot_split_rec.record_num
                     AND record_grp_id = p_group_id;

                  --COMMIT;
                  xxprop_common_util_pkg.trace_log
                     (p_module            =>    g_package_name
                                             || '.'
                                             || l_procedure_name,
                      p_message_text      =>    'Lot Split Transaction Completed with transaction_set_id-'
                                             || l_transaction_set_id,
                      p_payload           => NULL
                     );
               ELSE
                  --ROLLBACK;
                  l_err_msg :=
                             'Error Packing:-TransactionSet ID not generated';

                  /*UPDATE xxalg_wip_mo_tran_gt
                     SET record_status = 'E',
                         record_message = record_message || '|' || l_err_msg
                   WHERE record_grp_id = g_record_id
                         AND record_num = p_record_num;*/
                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'E',
                         record_message = record_message || '|' || l_err_msg
                   WHERE record_num = c_lot_split_rec.record_num
                     AND record_grp_id = p_group_id;

                  /*DELETE FROM mtl_transaction_lots_interface mtli
                        WHERE EXISTS (
                                 SELECT 1
                                   FROM mtl_transactions_interface mti
                                  WHERE mti.transaction_header_id =
                                                                  l_trx_hdr_id
                                    AND mtli.transaction_interface_id =
                                                  mti.transaction_interface_id);

                  DELETE FROM mtl_transactions_interface
                        WHERE transaction_header_id = l_trx_hdr_id;*/

                  --COMMIT;
                  xxprop_common_util_pkg.trace_log
                     (p_module            =>    g_package_name
                                             || '.'
                                             || l_procedure_name,
                      p_message_text      => 'Delete record from mtl_transactions_interface when l_transaction_set_id is null',
                      p_payload           => NULL
                     );
               END IF;
            ELSE
               BEGIN
                  SELECT 'Error Lot Merge:-' || error_explanation
                    INTO l_err_msg
                    FROM mtl_transactions_interface
                   WHERE transaction_header_id = l_trx_hdr_id
                     AND error_explanation IS NOT NULL
                     AND ROWNUM = 1;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_err_msg := NULL;
               END;

               --ROLLBACK;
               UPDATE xxalg_lpn_lot_split_merge_gt
                  SET record_status = 'E',
                      record_message = record_message || '|' || l_err_msg
                WHERE record_num = c_lot_split_rec.record_num
                  AND record_grp_id = p_group_id;

               /*DELETE FROM mtl_transaction_lots_interface mtli
                     WHERE EXISTS (
                              SELECT 1
                                FROM mtl_transactions_interface mti
                               WHERE mti.transaction_header_id = l_trx_hdr_id
                                 AND mtli.transaction_interface_id =
                                                  mti.transaction_interface_id);

               DELETE FROM mtl_transactions_interface
                     WHERE transaction_header_id = l_trx_hdr_id;*/

               --COMMIT;
               xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      => 'Delete record from mtl_transactions_interface when API get error',
                   p_payload           => NULL
                  );
            END IF;
         ELSE
            --ROLLBACK;
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || '|' || l_err_msg
             WHERE record_num = c_lot_split_rec.record_num
               AND record_grp_id = p_group_id;

            /*DELETE FROM mtl_transaction_lots_interface mtli
                  WHERE EXISTS (
                           SELECT 1
                             FROM mtl_transactions_interface mti
                            WHERE mti.transaction_header_id = l_trx_hdr_id
                              AND mtli.transaction_interface_id =
                                                  mti.transaction_interface_id);

            DELETE FROM mtl_transactions_interface
                  WHERE transaction_header_id = l_trx_hdr_id;*/

            --COMMIT;
            xxprop_common_util_pkg.trace_log
               (p_module            => g_package_name || '.'
                                       || l_procedure_name,
                p_message_text      =>    'Error while while inserting mtl_transactions_interface='
                                       || l_err_msg,
                p_payload           => NULL
               );
         END IF;
      END LOOP;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_msg := 'Exception in lot_split_interface:-' || SQLERRM;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => x_return_msg,
                                           p_payload           => NULL
                                          );
   END lot_split_interface;

   PROCEDURE lpn_split_interface (
      p_group_id        IN       NUMBER,
      x_return_status   IN OUT   VARCHAR2,
      x_return_msg      IN OUT   VARCHAR2
   )
   IS
      l_procedure_name   VARCHAR2 (200)  := 'LPN_SPLIT_INTERFACE';
      l_transaction_id   NUMBER;
      l_err_msg          VARCHAR2 (1000);
      l_record_status    VARCHAR2 (10);
      l_trx_hdr_id       NUMBER;
      l_mmt_api_return   NUMBER;
      l_mmt_trx_tmp_id   NUMBER;
      l_proc_msg         VARCHAR2 (4000);
      l_trx_api_return   NUMBER;
      l_check            NUMBER;
      l_ser_trx_id       NUMBER;

      --l_scrap_acct_chk   VARCHAR2 (10);
      CURSOR c_lpn_split_cur
      IS
         SELECT   *
             FROM xxalg_lpn_lot_split_merge_gt
            WHERE record_grp_id = p_group_id AND record_status = 'V'
         ORDER BY mobile_transaction_id, transaction_date ASC;
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );
      COMMIT;

      FOR c_lpn_split_rec IN c_lpn_split_cur
      LOOP
         l_err_msg := NULL;
         l_record_status := NULL;
         l_proc_msg := NULL;
         l_mmt_trx_tmp_id := NULL;
         l_trx_api_return := NULL;
         l_mmt_api_return := NULL;
         l_ser_trx_id := NULL;

         SELECT apps.mtl_material_transactions_s.NEXTVAL
           INTO l_trx_hdr_id
           FROM DUAL;

         l_mmt_api_return :=
            inv_trx_util_pub.insert_line_trx
               (p_trx_hdr_id             => l_trx_hdr_id,
                p_item_id                => c_lpn_split_rec.inventory_item_id,
                p_revision               => NULL,
                p_org_id                 => c_lpn_split_rec.inv_org_id,
                p_trx_action_id          => c_lpn_split_rec.transaction_action_id,
                p_subinv_code            => c_lpn_split_rec.source_sub_inventory,
                p_tosubinv_code          => NULL,
                p_locator_id             => c_lpn_split_rec.source_locator_id,
                p_tolocator_id           => NULL,
                p_xfr_org_id             => NULL,
                p_trx_type_id            => c_lpn_split_rec.transaction_type_id,
                p_trx_src_type_id        => c_lpn_split_rec.transaction_source_type_id,
                p_trx_qty                => c_lpn_split_rec.quantity,
                p_pri_qty                => c_lpn_split_rec.quantity,
                p_uom                    => c_lpn_split_rec.uom_code,
                p_date                   => c_lpn_split_rec.transaction_date,
                p_reason_id              => NULL,
                p_user_id                => c_lpn_split_rec.user_id,
                p_frt_code               => NULL,
                p_ship_num               => NULL,
                p_dist_id                => NULL,
                p_way_bill               => NULL,
                p_exp_arr                => NULL,
                p_cost_group             => NULL,
                p_from_lpn_id            => c_lpn_split_rec.source_lpn_id,
                p_cnt_lpn_id             => NULL,
                p_xfr_lpn_id             => c_lpn_split_rec.dest_lpn_id,
                p_trx_src_id             => NULL,
                p_xfr_cost_group         => NULL,
                p_completion_trx_id      => NULL,
                p_flow_schedule          => NULL,
                p_trx_cost               => NULL,
                p_project_id             => NULL,
                p_task_id                => NULL,
                p_secondary_trx_qty      => c_lpn_split_rec.secondary_quantity,
                p_secondary_uom          => c_lpn_split_rec.secondary_uom_code,
                x_trx_tmp_id             => l_mmt_trx_tmp_id,
                x_proc_msg               => l_proc_msg
               );
         xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      =>    'l_mmt_api_return-'
                                                          || l_mmt_api_return
                                                          || '  l_mmt_trx_tmp_id-'
                                                          || l_mmt_trx_tmp_id
                                                          || '  l_proc_msg-'
                                                          || l_proc_msg,
                                   p_payload           => NULL
                                  );

         IF c_lpn_split_rec.lot_number IS NOT NULL
         THEN
            l_proc_msg := NULL;
            l_ser_trx_id := NULL;
            l_mmt_api_return := NULL;
            l_mmt_api_return :=
               inv_trx_util_pub.insert_lot_trx
                      (p_trx_tmp_id         => l_mmt_trx_tmp_id,
                       p_user_id            => c_lpn_split_rec.user_id,
                       p_lot_number         => c_lpn_split_rec.lot_number,
                       p_trx_qty            => c_lpn_split_rec.quantity,
                       p_pri_qty            => c_lpn_split_rec.quantity,
                       p_secondary_uom      => c_lpn_split_rec.secondary_uom_code,
                       p_secondary_qty      => c_lpn_split_rec.secondary_quantity,
                       x_ser_trx_id         => l_ser_trx_id,
                       x_proc_msg           => l_proc_msg
                      );
            xxprop_common_util_pkg.trace_log
                            (p_module            =>    g_package_name
                                                    || '.'
                                                    || l_procedure_name,
                             p_message_text      =>    'l_mmt_api_return for lot-'
                                                    || l_mmt_api_return
                                                    || '  l_ser_trx_id-'
                                                    || l_ser_trx_id
                                                    || '  l_proc_msg-'
                                                    || l_proc_msg,
                             p_payload           => NULL
                            );
         END IF;

         IF c_lpn_split_rec.serial_number IS NOT NULL
         THEN
            l_proc_msg := NULL;
            l_ser_trx_id := NULL;
            l_mmt_api_return := NULL;
            l_mmt_api_return :=
               inv_trx_util_pub.insert_ser_trx
                           (p_trx_tmp_id            => NVL (l_ser_trx_id,
                                                            l_mmt_trx_tmp_id
                                                           ),
                            p_user_id               => c_lpn_split_rec.user_id,
                            p_fm_ser_num            => c_lpn_split_rec.serial_number,
                            p_to_ser_num            => c_lpn_split_rec.serial_number,
                            p_validation_level      => fnd_api.g_valid_level_full,
                            x_proc_msg              => l_proc_msg
                           );
            xxprop_common_util_pkg.trace_log
                         (p_module            =>    g_package_name
                                                 || '.'
                                                 || l_procedure_name,
                          p_message_text      =>    'l_mmt_api_return for Serial-'
                                                 || l_mmt_api_return
                                                 || '  l_ser_trx_id-'
                                                 || l_ser_trx_id
                                                 || '  l_proc_msg-'
                                                 || l_proc_msg,
                          p_payload           => NULL
                         );
         END IF;

         IF l_mmt_api_return = 0
         THEN
            l_proc_msg := NULL;
            l_trx_api_return :=
               inv_lpn_trx_pub.process_lpn_trx
                                            (p_trx_hdr_id              => l_trx_hdr_id,
                                             p_commit                  => fnd_api.g_false,
                                             x_proc_msg                => l_proc_msg,
                                             p_proc_mode               => NULL,
                                             p_process_trx             => fnd_api.g_true,
                                             p_atomic                  => fnd_api.g_false,
                                             p_business_flow_code      => 20
                                            );

            IF l_trx_api_return = 0
            THEN
               BEGIN
                  SELECT COUNT (*)
                    INTO l_check
                    FROM mtl_material_transactions
                   WHERE transaction_set_id = l_trx_hdr_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_check := 0;
               END;

               DBMS_OUTPUT.put_line (   ' l_mmt_trx_tmp_id-'
                                     || l_mmt_trx_tmp_id
                                     || '  l_trx_hdr_id'
                                     || l_trx_hdr_id
                                    );

               IF l_check > 0
               THEN
                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'S',
                         record_message = NULL,
                         transaction_id = l_trx_hdr_id
                   WHERE record_num = c_lpn_split_rec.record_num
                     AND record_grp_id = p_group_id;

                  COMMIT;
               ELSE
                  ROLLBACK;
                  l_record_status := 'E';
                  l_err_msg :=
                        l_err_msg
                     || '|'
                     || 'Error While Process Lpn Transaction, Transaction Set Id not Created-'
                     || l_proc_msg;

                  UPDATE xxalg_lpn_lot_split_merge_gt
                     SET record_status = 'E',
                         record_message = l_err_msg
                   WHERE record_num = c_lpn_split_rec.record_num
                     AND record_grp_id = p_group_id;

                  COMMIT;
                  xxprop_common_util_pkg.trace_log
                     (p_module            =>    g_package_name
                                             || '.'
                                             || l_procedure_name,
                      p_message_text      =>    'Error While Process Lpn Transaction, Transaction Set Id not Created-'
                                             || l_proc_msg,
                      p_payload           => NULL
                     );
               END IF;
            ELSE
               ROLLBACK;
               l_record_status := 'E';
               l_err_msg :=
                     l_err_msg
                  || '|'
                  || 'Error While Process Lpn Transaction-'
                  || l_proc_msg;

               UPDATE xxalg_lpn_lot_split_merge_gt
                  SET record_status = 'E',
                      record_message = l_err_msg
                WHERE record_num = c_lpn_split_rec.record_num
                  AND record_grp_id = p_group_id;

               COMMIT;
               xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      =>    'Error While Process Lpn Transaction-'
                                          || l_proc_msg,
                   p_payload           => NULL
                  );
            END IF;
         ELSE
            ROLLBACK;
            l_record_status := 'E';
            l_err_msg :=
                  l_err_msg
               || '|'
               || 'Error While Inserting MMT api-'
               || l_proc_msg;

            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = l_err_msg
             WHERE record_num = c_lpn_split_rec.record_num
               AND record_grp_id = p_group_id;

            COMMIT;
            xxprop_common_util_pkg.trace_log
                       (p_module            =>    g_package_name
                                               || '.'
                                               || l_procedure_name,
                        p_message_text      =>    'Error While Inserting MMT api-'
                                               || l_proc_msg,
                        p_payload           => NULL
                       );
         END IF;
      END LOOP;

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := 'E';
         x_return_msg := 'Exception in lpn_split_interface:-' || SQLERRM;
         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => x_return_msg,
                                           p_payload           => NULL
                                          );
   END lpn_split_interface;

   PROCEDURE lpn_split_main (p_clob CLOB, x_return_msg OUT CLOB)
   IS
      l_return_status      VARCHAR2 (10)    := 'S';
      l_return_exception   EXCEPTION;
      l_return_msg         VARCHAR2 (4000);
      l_qry                VARCHAR2 (32000);
      l_procedure_name     VARCHAR2 (100)   := 'LPN_SPLIT_MAIN';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      SELECT TO_NUMBER (TO_CHAR (SYS_EXTRACT_UTC (SYSTIMESTAMP), 'SSSSSFF3'))
        INTO g_group_id
        FROM DUAL;

      l_qry :=
            'SELECT MOBILE_TRANSACTION_ID "MobileTransactionId",DEST_LPN_ID "DestLpnId" '
         || ',INV_ORG_ID "InventoryOrgId",TRANSACTION_ID "TransactionId",RECORD_STATUS "ReturnStatus",replace(replace(record_message,chr(10),''|''),chr(13),'''') "ReturnMessage" '
         || 'FROM XXALG_LPN_LOT_SPLIT_MERGE_GT '
         || 'WHERE 1=1 AND RECORD_GRP_ID = '
         || g_group_id;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling insert_lpn_split_gtt');
         l_return_msg := NULL;
         insert_lpn_split_gtt (p_group_id           => g_group_id,
                               p_clob               => p_clob,
                               x_return_status      => l_return_status,
                               x_return_msg         => l_return_msg
                              );
         xxprop_common_util_pkg.trace_log
                 (p_module            =>    g_package_name
                                         || '.'
                                         || l_procedure_name,
                  p_message_text      =>    'insert_lpn_split_gtt Return Status- '
                                         || l_return_status
                                         || ' Return Message- '
                                         || l_return_msg,
                  p_payload           => NULL
                 );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling validate_lpn_split_data');
         l_return_msg := NULL;
         validate_lpn_split_data (p_group_id           => g_group_id,
                                  x_return_status      => l_return_status,
                                  x_return_msg         => l_return_msg
                                 );
         xxprop_common_util_pkg.trace_log
            (p_module            => g_package_name || '.' || l_procedure_name,
             p_message_text      =>    ' validate_lpn_split_data Return Status - '
                                    || l_return_status
                                    || ' Return Message- '
                                    || l_return_msg,
             p_payload           => NULL
            );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling lpn_split_interface');
         l_return_msg := NULL;
         lpn_split_interface (p_group_id           => g_group_id,
                              x_return_status      => l_return_status,
                              x_return_msg         => l_return_msg
                             );
         xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      =>    'lpn_split_interface Return Status- '
                                          || l_return_status
                                          || ' Return Message- '
                                          || l_return_msg,
                   p_payload           => NULL
                  );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
        INTO x_return_msg
        FROM DUAL;

      DELETE FROM xxalg_lpn_lot_split_merge_gt
            WHERE record_grp_id = g_group_id;                 --Comment Delete

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN l_return_exception
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => 'ERROR',
                                           p_payload           => NULL
                                          );

         DELETE FROM xxalg_lpn_lot_split_merge_gt
               WHERE record_grp_id = g_group_id;              --Comment Delete
      WHEN OTHERS
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      =>    'ERROR-'
                                                                  || SQLERRM,
                                           p_payload           => NULL
                                          );

         DELETE FROM xxalg_lpn_lot_split_merge_gt
               WHERE record_grp_id = g_group_id;              --Comment Delete
   END lpn_split_main;

   PROCEDURE lpn_merge_main (p_clob CLOB, x_return_msg OUT CLOB)
   IS
      l_return_status      VARCHAR2 (10)    := 'S';
      l_return_exception   EXCEPTION;
      l_return_msg         VARCHAR2 (4000);
      l_qry                VARCHAR2 (32000);
      l_procedure_name     VARCHAR2 (100)   := 'LPN_MERGE_MAIN';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      SELECT TO_NUMBER (TO_CHAR (SYS_EXTRACT_UTC (SYSTIMESTAMP), 'SSSSSFF3'))
        INTO g_group_id
        FROM DUAL;

      l_qry :=
            'SELECT MOBILE_TRANSACTION_ID "MobileTransactionId",DEST_LPN_ID "DestLpnId" '
         || ',INV_ORG_ID "InventoryOrgId",TRANSACTION_ID "TransactionId",RECORD_STATUS "ReturnStatus",replace(replace(record_message,chr(10),''|''),chr(13),'''') "ReturnMessage" '
         || 'FROM XXALG_LPN_LOT_SPLIT_MERGE_GT '
         || 'WHERE 1=1 AND RECORD_GRP_ID = '
         || g_group_id;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling insert_lpn_merge_gtt');
         l_return_msg := NULL;
         insert_lpn_merge_gtt (p_group_id           => g_group_id,
                               p_clob               => p_clob,
                               x_return_status      => l_return_status,
                               x_return_msg         => l_return_msg
                              );
         xxprop_common_util_pkg.trace_log
                 (p_module            =>    g_package_name
                                         || '.'
                                         || l_procedure_name,
                  p_message_text      =>    'insert_lpn_merge_gtt Return Status- '
                                         || l_return_status
                                         || ' Return Message- '
                                         || l_return_msg,
                  p_payload           => NULL
                 );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling validate_lpn_merge_data');
         l_return_msg := NULL;
         validate_lpn_merge_data (p_group_id           => g_group_id,
                                  x_return_status      => l_return_status,
                                  x_return_msg         => l_return_msg
                                 );
         xxprop_common_util_pkg.trace_log
            (p_module            => g_package_name || '.' || l_procedure_name,
             p_message_text      =>    ' validate_lpn_merge_data Return Status - '
                                    || l_return_status
                                    || ' Return Message- '
                                    || l_return_msg,
             p_payload           => NULL
            );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling lpn_merge_interface');
         l_return_msg := NULL;
         lpn_merge_interface (p_group_id           => g_group_id,
                              x_return_status      => l_return_status,
                              x_return_msg         => l_return_msg
                             );
         xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      =>    'lpn_merge_interface Return Status- '
                                          || l_return_status
                                          || ' Return Message- '
                                          || l_return_msg,
                   p_payload           => NULL
                  );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
        INTO x_return_msg
        FROM DUAL;

      DELETE FROM xxalg_lpn_lot_split_merge_gt
            WHERE record_grp_id = g_group_id;                 --Comment Delete

      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN l_return_exception
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => 'ERROR',
                                           p_payload           => NULL
                                          );

         DELETE FROM xxalg_lpn_lot_split_merge_gt
               WHERE record_grp_id = g_group_id;              --Comment Delete
      WHEN OTHERS
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      =>    'ERROR-'
                                                                  || SQLERRM,
                                           p_payload           => NULL
                                          );

         DELETE FROM xxalg_lpn_lot_split_merge_gt
               WHERE record_grp_id = g_group_id;              --Comment Delete
   END lpn_merge_main;

 PROCEDURE lot_split_main (p_clob CLOB, x_return_msg OUT CLOB)
   IS
      l_return_status      VARCHAR2 (10)    := 'S';
      l_return_exception   EXCEPTION;
      l_return_msg         VARCHAR2 (4000);
      l_qry                VARCHAR2 (32000);
      l_procedure_name     VARCHAR2 (100)   := 'LOT_SPLIT_MAIN';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      SELECT TO_NUMBER (TO_CHAR (SYS_EXTRACT_UTC (SYSTIMESTAMP), 'SSSSSFF3'))
        INTO g_group_id
        FROM DUAL;

      l_qry :=
            'SELECT MOBILE_TRANSACTION_ID "MobileTransactionId",LOT_NUMBER "SourceLotNumber",SOURCE_LPN_ID "SourceLpnId",DEST_LOT_NUMBER "DestLotNumber",DEST_LPN_ID "Destlpnid"'
         || ',INV_ORG_ID "InventoryOrgId",TRANSACTION_ID "TransactionId",RECORD_STATUS "ReturnStatus",replace(replace(record_message,chr(10),''|''),chr(13),'''') "ReturnMessage" '
         || 'FROM XXALG_LPN_LOT_SPLIT_MERGE_GT '
         || 'WHERE 1=1 AND RECORD_GRP_ID = '
         || g_group_id;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling insert_lot_split_gtt');
         l_return_msg := NULL;
         insert_lot_split_gtt (p_group_id           => g_group_id,
                               p_clob               => p_clob,
                               x_return_status      => l_return_status,
                               x_return_msg         => l_return_msg
                              );
         xxprop_common_util_pkg.trace_log
                 (p_module            =>    g_package_name
                                         || '.'
                                         || l_procedure_name,
                  p_message_text      =>    'insert_lot_split_gtt Return Status- '
                                         || l_return_status
                                         || ' Return Message- '
                                         || l_return_msg,
                  p_payload           => NULL
                 );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling validate_lot_split_data');
         l_return_msg := NULL;
         validate_lot_split_data (p_group_id           => g_group_id,
                                  x_return_status      => l_return_status,
                                  x_return_msg         => l_return_msg
                                 );
         xxprop_common_util_pkg.trace_log
            (p_module            => g_package_name || '.' || l_procedure_name,
             p_message_text      =>    ' validate_lot_split_data Return Status - '
                                    || l_return_status
                                    || ' Return Message- '
                                    || l_return_msg,
             p_payload           => NULL
            );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling lot_split_interface');
         l_return_msg := NULL;
         lot_split_interface (p_group_id           => g_group_id,
                              x_return_status      => l_return_status,
                              x_return_msg         => l_return_msg
                             );
         xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      =>    'lot_split_interface Return Status- '
                                          || l_return_status
                                          || ' Return Message- '
                                          || l_return_msg,
                   p_payload           => NULL
                  );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
        INTO x_return_msg
        FROM DUAL;

      --DELETE FROM xxalg_lpn_lot_split_merge_gt
           -- WHERE record_grp_id = g_group_id;                 --Comment Delete
      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN l_return_exception
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => 'ERROR',
                                           p_payload           => NULL
                                          );
      --DELETE FROM xxalg_lpn_lot_split_merge_gt
           -- WHERE record_grp_id = g_group_id;              --Comment Delete
      WHEN OTHERS
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      =>    'ERROR-'
                                                                  || SQLERRM,
                                           p_payload           => NULL
                                          );
   --DELETE FROM xxalg_lpn_lot_split_merge_gt
         --WHERE record_grp_id = g_group_id;              --Comment Delete
   END lot_split_main;

   PROCEDURE lot_merge_main (p_clob CLOB, x_return_msg OUT CLOB)
   IS
      l_return_status      VARCHAR2 (10)    := 'S';
      l_return_exception   EXCEPTION;
      l_return_msg         VARCHAR2 (4000);
      l_qry                VARCHAR2 (32000);
      l_procedure_name     VARCHAR2 (100)   := 'LOT_MERGE_MAIN';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                 (p_module            =>    g_package_name
                                                         || '.'
                                                         || l_procedure_name,
                                  p_message_text      => 'Start of the Procedure',
                                  p_payload           => NULL
                                 );

      SELECT TO_NUMBER (TO_CHAR (SYS_EXTRACT_UTC (SYSTIMESTAMP), 'SSSSSFF3'))
        INTO g_group_id
        FROM DUAL;

      l_qry :=
            'SELECT MOBILE_TRANSACTION_ID "MobileTransactionId",LOT_NUMBER "SourceLotNumber",SOURCE_LPN_ID "SourceLpnId",DEST_LOT_NUMBER "DestLotNumber",DEST_LPN_ID "Destlpnid"'
         || ',INV_ORG_ID "InventoryOrgId",TRANSACTION_ID "TransactionId",RECORD_STATUS "ReturnStatus",replace(replace(record_message,chr(10),''|''),chr(13),'''') "ReturnMessage" '
         || 'FROM XXALG_LPN_LOT_SPLIT_MERGE_GT '
         || 'WHERE 1=1 AND RECORD_GRP_ID = '
         || g_group_id;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling insert_lot_merge_gtt');
         l_return_msg := NULL;
         insert_lot_merge_gtt (p_group_id           => g_group_id,
                               p_clob               => p_clob,
                               x_return_status      => l_return_status,
                               x_return_msg         => l_return_msg
                              );
         xxprop_common_util_pkg.trace_log
                 (p_module            =>    g_package_name
                                         || '.'
                                         || l_procedure_name,
                  p_message_text      =>    'insert_lot_merge_gtt Return Status- '
                                         || l_return_status
                                         || ' Return Message- '
                                         || l_return_msg,
                  p_payload           => NULL
                 );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling validate_lot_merge_data');
         l_return_msg := NULL;
         validate_lot_merge_data (p_group_id           => g_group_id,
                                  x_return_status      => l_return_status,
                                  x_return_msg         => l_return_msg
                                 );
         xxprop_common_util_pkg.trace_log
            (p_module            => g_package_name || '.' || l_procedure_name,
             p_message_text      =>    ' validate_lot_merge_data Return Status - '
                                    || l_return_status
                                    || ' Return Message- '
                                    || l_return_msg,
             p_payload           => NULL
            );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      BEGIN
         DBMS_OUTPUT.put_line ('Calling lot_merge_interface');
         l_return_msg := NULL;
         lot_merge_interface (p_group_id           => g_group_id,
                              x_return_status      => l_return_status,
                              x_return_msg         => l_return_msg
                             );
         xxprop_common_util_pkg.trace_log
                  (p_module            =>    g_package_name
                                          || '.'
                                          || l_procedure_name,
                   p_message_text      =>    'lot_merge_interface Return Status- '
                                          || l_return_status
                                          || ' Return Message- '
                                          || l_return_msg,
                   p_payload           => NULL
                  );

         IF l_return_status <> 'S'
         THEN
            UPDATE xxalg_lpn_lot_split_merge_gt
               SET record_status = 'E',
                   record_message = record_message || ' ' || l_return_msg
             WHERE record_grp_id = g_group_id;

            RAISE l_return_exception;
         END IF;
      END;

      SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
        INTO x_return_msg
        FROM DUAL;

      --DELETE FROM xxalg_lpn_lot_split_merge_gt
           -- WHERE record_grp_id = g_group_id;                 --Comment Delete
      xxprop_common_util_pkg.trace_log
                                    (p_module            =>    g_package_name
                                                            || '.'
                                                            || l_procedure_name,
                                     p_message_text      => 'End of the Procedure',
                                     p_payload           => NULL
                                    );
   EXCEPTION
      WHEN l_return_exception
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      => 'ERROR',
                                           p_payload           => NULL
                                          );
      --DELETE FROM xxalg_lpn_lot_split_merge_gt
           -- WHERE record_grp_id = g_group_id;              --Comment Delete
      WHEN OTHERS
      THEN
         BEGIN
            SELECT xxprop_common_util_pkg.get_jason_output (l_qry)
              INTO x_return_msg
              FROM DUAL;
         END;

         xxprop_common_util_pkg.trace_log (p_module            =>    g_package_name
                                                                  || '.'
                                                                  || l_procedure_name,
                                           p_message_text      =>    'ERROR-'
                                                                  || SQLERRM,
                                           p_payload           => NULL
                                          );
   --DELETE FROM xxalg_lpn_lot_split_merge_gt
         --WHERE record_grp_id = g_group_id;              --Comment Delete
   END lot_merge_main;
END xxalg_lpn_lot_split_merge_pkg;
/

