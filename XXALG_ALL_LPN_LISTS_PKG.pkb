CREATE OR REPLACE PACKAGE BODY xxalg_all_lpn_lists_pkg
AS
   /* *****************************************************************************************
   ||   FILENAME         : XXALG_ALL_LPN_LISTS_PKG.pkb                                        ||
   ||   Project          : Mobile Manufacturing                                               ||
   ||   Description      : Package Body which have functions to fetch all LPN  API details    ||
   ||   AUTHOR           : Satish Addala                                                      ||
   ||   DATE             : 10-FEB-2020                                                        ||
   ||   NOTES            : R12                                                                ||
   ||                                                                                         ||
   ||   VER     DATE            AUTHOR               MODIFICATION          xcvxvxcvxc                   ||
   ||   -----   -------------   ----------------     -------------------                      ||
   ||   1.0     10-FEB-2020    Satish Addala         Initial version                          ||
   ||                                                                                         ||
   ********************************************************************************************/

   /* *******************************************************************************************
   ||   FUNCTION         :  print_debug_p                                                       ||
   ||   Description      :  Function to get debug messages                                      ||
   ||                                                                                           ||
   ||    VER     DATE            AUTHOR               MODIFICATION                              ||
   ||   -----   -------------   ----------------     -------------------                        ||
   ||   1.0     03-July-2019     Pallavi Nakka         Initial version     vvvzvz                     ||
   ||                                                                                           ||
   ||                                                                                           ||
   ***********************************************************************************************/
   g_package_name   VARCHAR2 (100) := 'XXALG_ALL_LPN_LISTS_PKG';

   PROCEDURE print_debug_p (p_msg IN VARCHAR2)
   AS
   BEGIN
      DBMS_OUTPUT.put_line (   'DEBUG('
                            || TO_CHAR (SYSDATE, 'YYYYMMDD HH24:MI:SS')
                            || ')   :'
                            || p_msg
                           );
   END print_debug_p;

    /* ************************************************************************************
   ||   FUNCTION         :  GET_ASS_COMP_LPN_LIST_F                                     ||
   ||   Description      :  Function to get LPN Details of the WIP Completion           ||
   ||                                                                                   ||
   ||   VER     DATE            AUTHOR               MODIFICATION                       ||
   ||   -----   -------------   ----------------     -------------------                ||
   ||   1.0     10-FEB-2020     Satish Addala         Initial version                   ||
   ||                                                                                   ||
   ***************************************************************************************/
   FUNCTION get_ass_comp_lpn_list_f (
      p_organization_id   IN   NUMBER,
      p_last_refresh      IN   VARCHAR2,
      p_full_refresh      IN   CHAR DEFAULT 'N'
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_ASS_COMP_LPN_LIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'lpn.LPN_ID,lpn.Organization_ID Org_ID, lpn.License_Plate_Number LPN_Number,lpn.Inventory_Item_ID Inventory_ID, '
         || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,lpn.LPN_Context,lpn.Outermost_LPN_ID, '
         || 'MSI.PRIMARY_UOM_CODE PRIMARY_UOM,WLC.SECONDARY_UOM_CODE SECONDARY_UOM,WLC.SECONDARY_QUANTITY, '
         || 'msi.Concatenated_Segments Items,mil.Concatenated_Segments Locators,FLV.Meaning,NULL DATA_RECORD_FLAG '
         || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV,WMS_LPN_CONTENTS WLC '
         || 'WHERE lpn.Organization_ID = msi.Organization_ID (+) '
         || 'AND lpn.Organization_ID = mil.Organization_ID (+) '
         || 'AND LPN.ORGANIZATION_ID = WLC.ORGANIZATION_ID(+) '
         || 'AND lpn.Organization_ID = '
         || p_organization_id
         || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID(+) '
         || 'and trunc(lpn.last_update_date) between  trunc(sysdate)-365 and  trunc(sysdate ) '
         || 'AND lpn.Inventory_Item_id = msi.Inventory_Item_id (+) '
         || 'AND lpn.locator_id = mil.inventory_location_id (+) '
         || 'AND FLV.Lookup_Code = lpn.LPN_Context '
         || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
         || 'AND FLV.language = userenv(''LANG'') '
         || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
         || 'AND FLV.enabled_flag = ''Y'' '
         || 'AND LPN_CONTEXT in (5) and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') ';

      IF p_full_refresh = 'N'
      THEN
         v_qry :=
               v_qry
            || ' AND lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')';
         v_qry :=
               v_qry
            || 'UNION SELECT lpn.LPN_ID,lpn.Organization_ID Org_ID, lpn.License_Plate_Number LPN_Number,lpn.Inventory_Item_ID Inventory_ID, '
            || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,lpn.LPN_Context,lpn.Outermost_LPN_ID, '
            || 'MSI.PRIMARY_UOM_CODE PRIMARY_UOM,WLC.SECONDARY_UOM_CODE SECONDARY_UOM,WLC.SECONDARY_QUANTITY, '
            || 'msi.Concatenated_Segments Items,mil.Concatenated_Segments Locators,FLV.Meaning, ''D'' DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV,WMS_LPN_CONTENTS WLC '
            || 'WHERE lpn.Organization_ID = msi.Organization_ID (+) '
            || 'AND lpn.Organization_ID   = mil.Organization_ID (+) '
            || 'AND lpn.Organization_ID   = '
            || p_organization_id
            || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID(+) '
            || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID(+) '
            || 'AND lpn.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 'AND lpn.locator_id        = mil.inventory_location_id (+) '
            || 'AND FLV.Lookup_Code        = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type        = ''WMS_LPN_CONTEXT'' '
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' '
            || 'AND LPN_CONTEXT in (1)  and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
            || 'AND lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'') ';
         v_qry := 'SELECT ' || v_qry;
      ELSE
         v_qry := 'SELECT DISTINCT ' || v_qry;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
                (p_module            =>    g_package_name
                                        || '.'
                                        || l_procedure_name,
                 p_message_text      => 'ERROR',
                 p_payload           => 'NO_DATA_FOUND in LPNs for WIPCompletion Query'
                );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'After executing query',
          p_payload           => 'EXECUTION SUCCESFULL FOR XXALG_ALL_LPN_LISTS_PKG.GET_ASS_COMP_LPN_LIST_F'
         );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_ASS_COMP_LPN_LIST_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   END get_ass_comp_lpn_list_f;

   FUNCTION get_all_lpns (
      p_organization_id   IN   NUMBER,
      p_name              IN   VARCHAR2,
      p_date_from         IN   VARCHAR2,
      p_date_to           IN   VARCHAR2
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_ALL_LPNS';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);

      /* Query to get LPN's for WIPCompletion list details */
      IF p_name = 'WIP_COMPLETE'
      THEN
         v_qry :=
               ' SELECT DISTINCT lpn.LPN_ID,lpn.Organization_ID Org_ID, lpn.License_Plate_Number LPN_Number, '
            || 'lpn.Parent_LPN_ID,lpn.LPN_Context,lpn.Outermost_LPN_ID, '
            || 'FLV.Meaning,NULL DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV,WMS_LPN_CONTENTS WLC '
            || 'WHERE lpn.Organization_ID = msi.Organization_ID (+) '
            || 'AND lpn.Organization_ID = mil.Organization_ID (+) '
            || 'AND LPN.ORGANIZATION_ID = WLC.ORGANIZATION_ID(+) '
            || 'AND lpn.Organization_ID = '
            || p_organization_id
            || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID(+) '
            || 'and trunc(lpn.last_update_date) between  trunc(sysdate)-365 and  trunc(sysdate ) '
            || 'AND lpn.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 'AND lpn.locator_id = mil.inventory_location_id (+) '
            || 'AND FLV.Lookup_Code = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' '
            || 'AND  not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
            || 'AND LPN_CONTEXT in (5)'
            || 'AND lpn.last_update_date BETWEEN  TO_DATE('''
            || p_date_from
            || ''', ''DD-MON-RRRR HH24:MI:SS'')'
            || ' AND TO_DATE('''
            || p_date_to
            || ''', ''DD-MON-RRRR HH24:MI:SS'') ';
      END IF;

      IF p_name = 'UNPACK'
      THEN
         v_qry :=
               'select distinct lpn.License_Plate_Number LPN_Number,WLC.Inventory_Item_ID Inventory_item_id, '
            || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,trim (replace(replace(replace(replace (msi.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION '
            || ',lpn.LPN_Context,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.Outermost_LPN_ID,MSI.Concatenated_Segments Item, '
            || 'msi.primary_uom_code uom_code,mil.Concatenated_Segments Locators,WLC.LOT_NUMBER, '
            || 'WLC.QUANTITY PACKED_QUANTITY,NULL UnPackQty,NULL DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV '
            || ',wms_lpn_contents WLC '
            || 'WHERE lpn.Organization_ID = mil.Organization_ID  '
            || 'AND WLC.Organization_ID = msi.Organization_ID (+) '
            || 'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) '
            || 'AND lpn.locator_id = mil.inventory_location_id (+) '
            || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 
               -- 'and trunc(lpn.last_update_date) between  trunc(sysdate)-365 and  trunc(sysdate ) '||
               'AND LPN.LPN_ID = WLC.PARENT_LPN_ID '
            || 'AND FLV.Lookup_Code = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
            || 'AND LPN.LPN_Context  in (1) '
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
            || 'AND lpn.last_update_date BETWEEN  TO_DATE('''
            || p_date_from
            || ''', ''DD-MON-RRRR HH24:MI:SS'')'
            || ' AND TO_DATE('''
            || p_date_to
            || ''', ''DD-MON-RRRR HH24:MI:SS'') '
            || 'AND lpn.Organization_ID = '
            || p_organization_id;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
                (p_module            =>    g_package_name
                                        || '.'
                                        || l_procedure_name,
                 p_message_text      => 'ERROR',
                 p_payload           => 'NO_DATA_FOUND in LPNs for WIPCompletion Query'
                );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'After executing query',
          p_payload           => 'EXECUTION SUCCESFULL FOR XXALG_ALL_LPN_LISTS_PKG.GET_ASS_COMP_LPN_LIST_F'
         );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_ASS_COMP_LPN_LIST_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   END get_all_lpns;

   /* ************************************************************************************
   ||   FUNCTION         :  GET_SUB_INV_TRANS_LPN_lIST_F                               ||
   ||   Description      :  Function to get LPN Details of the Sub Inventory Transfer   ||
   ||                                                                                   ||
   ||   VER     DATE            AUTHOR               MODIFICATION                       ||
   ||   -----   -------------   ----------------     -------------------                ||
   ||   1.0     10-FEB-2020     Satish Addala         Initial version                   ||
   ||                                                                                   ||
   ***************************************************************************************/
   FUNCTION get_sub_inv_trans_lpn_list_f (
      p_organization_id   IN   NUMBER,
      p_last_refresh      IN   VARCHAR2,
      p_full_refresh      IN   CHAR DEFAULT 'N'
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_SUB_INV_TRANS_LPN_lIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,WLC.Inventory_Item_ID Inventory_item_id, '
         || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,trim (replace(replace(replace(replace (msi.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION '
         || ',lpn.LPN_Context,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.REVISION,lpn.Outermost_LPN_ID,MSI.Concatenated_Segments Item, '
         || 'msi.primary_uom_code uom_code,wlc.secondary_uom_code secondary_uom,wlc.secondary_quantity,mil.Concatenated_Segments Locators, '
         || 'FLV.Meaning,WLC.QUANTITY PACKED_QUANTITY,NULL UnPackQty,NULL DATA_RECORD_FLAG '
         || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV '
         || ',wms_lpn_contents WLC '
         || 'WHERE lpn.Organization_ID = mil.Organization_ID (+) '
         || 'AND WLC.Organization_ID = msi.Organization_ID (+) '
         || 'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) '
         || 'AND lpn.locator_id = mil.inventory_location_id (+) '
         || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
         || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID '
         || 'AND FLV.Lookup_Code = lpn.LPN_Context '
         || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
         || 'AND LPN.LPN_Context IN (1) '
         || 'AND FLV.language = userenv(''LANG'') '
         || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
         || 'AND FLV.enabled_flag = ''Y''  and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
         || 'AND lpn.Organization_ID = '
         || p_organization_id;

      IF p_full_refresh = 'N'
      THEN
         v_qry :=
               v_qry
            || 'AND ((lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) '
            || 'OR (WLC.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS''))) ';
         v_qry :=
               v_qry
            || 'UNION SELECT lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,NULL Inventory_item_id, '
            || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,NULL ITEM_DESCRIPTION '
            || ',lpn.LPN_Context,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.REVISION,lpn.Outermost_LPN_ID,NULL Item, '
            || 'msi.primary_uom_code uom_code,wlc.secondary_uom_code secondary_uom,wlc.secondary_quantity,mil.Concatenated_Segments Locators, '
            || 'FLV.Meaning,NULL PACKED_QUANTITY,NULL UnPackQty,''D'' DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV,wms_lpn_contents wlc  '
            || 'WHERE lpn.Organization_ID = mil.Organization_ID (+) '
            || 'AND lpn.locator_id = mil.inventory_location_id (+) '
            || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 
               --'AND WLC.Organization_ID = msi.Organization_ID (+) ' ||
               ---'AND LPN.LPN_ID = WLC.PARENT_LPN_ID ' ||
               ---'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) ' ||
               'AND FLV.Lookup_Code = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
            || 'AND lpn.Organization_ID = '
            || p_organization_id
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND LPN.LPN_Context NOT IN (1) '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
            || 'AND (lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) ';
         v_qry := 'SELECT DISTINCT ' || v_qry;
      ELSE
         v_qry := 'SELECT DISTINCT ' || v_qry;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'ERROR',
               p_payload           => 'NO_DATA_FOUND in LPNs For Subinv transfer Query'
              );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'After executing query',
          p_payload           => 'EXECUTION SUCCESFULL FOR XXALG_ALL_LPN_LISTS_PKG.GET_SUB_INV_TRANS_LPN_LIST_F'
         );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_SUB_INV_TRANS_LPN_LIST_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   END get_sub_inv_trans_lpn_list_f;

   /* ************************************************************************************
   ||   FUNCTION         :  GET_PUTAWAY_LPN_lIST_F                                      ||
   ||   Description      :  Function to get LPN Details of the Putaway                  ||
   ||                                                                                   ||
   ||   VER     DATE            AUTHOR               MODIFICATION                       ||
   ||   -----   -------------   ----------------     -------------------                ||
   ||   1.0     15-OCT-2020     Mounika Parepalli     Initial version                   ||
   ||                                                                                   ||
   ***************************************************************************************/
   FUNCTION get_putaway_lpn_list_f (
      p_organization_id   IN   NUMBER,
      p_last_refresh      IN   VARCHAR2,
      p_full_refresh      IN   CHAR DEFAULT 'N'
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_PUTAWAY_LPN_lIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,WLC.Inventory_Item_ID, '
         || 'MSI.Concatenated_Segments ITEM,trim (replace(replace(replace(replace (msi.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION, '
         || 'msi.primary_uom_code uom_code,wlc.secondary_uom_code secondary_uom,lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID, '
         || 'mil.Concatenated_Segments Locator,lpn.Parent_LPN_ID,wlc.quantity,wlc.secondary_quantity, '
         || 'lpn.LPN_Context,FLV.Meaning,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.REVISION, '
         || 'lpn.Outermost_LPN_ID,NULL DATA_RECORD_FLAG '
         || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV '
         || ',wms_lpn_contents WLC '
         || 'WHERE lpn.Organization_ID = mil.Organization_ID (+) '
         || 'AND WLC.Organization_ID = msi.Organization_ID (+) '
         || 'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) '
         || 'AND lpn.locator_id = mil.inventory_location_id (+) '
         || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
         || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID '
         || 'AND FLV.Lookup_Code = lpn.LPN_Context '
         || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
         || 'AND FLV.language = userenv(''LANG'') '
         || 'AND lpn.Organization_ID   = '
         || p_organization_id
         || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
         || 'AND FLV.enabled_flag = ''Y'' and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
         || 'AND LPN.LPN_Context IN (3)';

      IF p_full_refresh = 'N'
      THEN
         v_qry :=
               v_qry
            || 'AND ((lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) '
            || 'OR (WLC.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS''))) ';
         v_qry :=
               v_qry
            || 'union select lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,WLC.Inventory_Item_ID, '
            || 'MSI.Concatenated_Segments ITEM,trim (replace(replace(replace(replace (msi.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION, '
            || 'msi.primary_uom_code uom_code,wlc.secondary_uom_code secondary_uom,lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID, '
            || 'mil.Concatenated_Segments Locator,lpn.Parent_LPN_ID,wlc.quantity,wlc.secondary_quantity, '
            || 'lpn.LPN_Context,FLV.Meaning,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.REVISION, '
            || 'lpn.Outermost_LPN_ID,''D'' DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV '
            || ',wms_lpn_contents WLC '
            || 'WHERE lpn.Organization_ID = mil.Organization_ID (+) '
            || 'AND WLC.Organization_ID = msi.Organization_ID (+) '
            || 'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) '
            || 'AND lpn.locator_id = mil.inventory_location_id (+) '
            || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID '
            || 'AND FLV.Lookup_Code = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
            || 'AND lpn.Organization_ID   = '
            || p_organization_id
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' '
            || 'AND LPN.LPN_Context NOT IN (3) and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
            || 'AND ((lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) '
            || 'OR (WLC.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS''))) ';
         v_qry := 'SELECT DISTINCT ' || v_qry;
      ELSE
         v_qry := 'SELECT DISTINCT ' || v_qry;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
                      (p_module            =>    g_package_name
                                              || '.'
                                              || l_procedure_name,
                       p_message_text      => 'ERROR',
                       p_payload           => 'NO_DATA_FOUND in LPNs For Putaway Query'
                      );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'After executing query',
          p_payload           => 'EXECUTION SUCCESFULL FOR XXALG_ALL_LPN_LISTS_PKG.GET_PUTAWAY_LPN_LIST_F'
         );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_PUTAWAY_LPN_LIST_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   END get_putaway_lpn_list_f;

   /* ************************************************************************************
   ||   FUNCTION         :  GET_GR_LPN_LIST_F                                           ||
   ||   Description      :  Function to get LPN Details of the goods receipt            ||
   ||                                                                                   ||
   ||   VER     DATE            AUTHOR               MODIFICATION                       ||
   ||   -----   -------------   ----------------     -------------------                ||
   ||   1.0     15-OCT-2020     Mounika Parepalli     Initial version                   ||
   ||                                                                                   ||
   ***************************************************************************************/
   FUNCTION get_gr_lpn_list_f (
      p_organization_id   IN   NUMBER,
      p_last_refresh      IN   VARCHAR2,
      p_full_refresh      IN   CHAR DEFAULT 'N'
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_GR_LPN_LIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,WLC.Inventory_Item_ID Inventory_item_id, '
         || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,trim (replace(replace(replace(replace (msi.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION '
         || ',lpn.LPN_Context,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.REVISION,lpn.Outermost_LPN_ID,MSI.Concatenated_Segments Item, '
         || 'msi.primary_uom_code uom_code,wlc.secondary_uom_code secondary_uom,mil.Concatenated_Segments Locators, '
         || 'FLV.Meaning,WLC.QUANTITY PACKED_QUANTITY,wlc.secondary_quantity,NULL UnPackQty,NULL DATA_RECORD_FLAG '
         || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV '
         || ',wms_lpn_contents WLC '
         || 'WHERE lpn.Organization_ID = mil.Organization_ID (+) '
         || 'AND WLC.Organization_ID = msi.Organization_ID (+) '
         || 'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) '
         || 'AND lpn.locator_id = mil.inventory_location_id (+) '
         || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
         || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID (+) '
         || 'AND FLV.Lookup_Code = lpn.LPN_Context '
         || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
         || 'AND LPN.LPN_Context IN (1,3,5) '
         || 'AND FLV.language = userenv(''LANG'') '
         || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
         || 'AND FLV.enabled_flag = ''Y''  and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
         || 'AND lpn.Organization_ID = '
         || p_organization_id;

      IF p_full_refresh = 'N'
      THEN
         v_qry :=
               v_qry
            || 'AND ((lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) '
            || 'OR (WLC.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS''))) ';
         v_qry :=
               v_qry
            || 'UNION SELECT lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,WLC.Inventory_Item_ID Inventory_item_id, '
            || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,trim (replace(replace(replace(replace (msi.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION '
            || ',lpn.LPN_Context,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.REVISION,lpn.Outermost_LPN_ID,MSI.Concatenated_Segments Item, '
            || 'msi.primary_uom_code uom_code,wlc.secondary_uom_code secondary_uom,mil.Concatenated_Segments Locators, '
            || 'FLV.Meaning,WLC.QUANTITY PACKED_QUANTITY,wlc.secondary_quantity,NULL UnPackQty,''D'' DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV '
            || ',wms_lpn_contents WLC '
            || 'WHERE lpn.Organization_ID = mil.Organization_ID (+) '
            || 'AND WLC.Organization_ID = msi.Organization_ID (+) '
            || 'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) '
            || 'AND lpn.locator_id = mil.inventory_location_id (+) '
            || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID (+) '
            || 'AND FLV.Lookup_Code = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
            || 'AND LPN.LPN_Context NOT IN (1,3,5) '
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
            || 'AND lpn.Organization_ID = '
            || p_organization_id
            || 'AND ((lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) '
            || 'OR (WLC.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS''))) ';
         v_qry := 'SELECT DISTINCT ' || v_qry;
      ELSE
         v_qry := 'SELECT DISTINCT ' || v_qry;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
                      (p_module            =>    g_package_name
                                              || '.'
                                              || l_procedure_name,
                       p_message_text      => 'ERROR',
                       p_payload           => 'NO_DATA_FOUND in LPNs For Receipt Query'
                      );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
         (p_module            => g_package_name || '.' || l_procedure_name,
          p_message_text      => 'After executing query',
          p_payload           => 'EXECUTION SUCCESFULL FOR XXALG_ALL_LPN_LISTS_PKG.GET_GR_LPN_LIST_F'
         );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;zxczxcz
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_GR_LPN_LIST_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   END get_gr_lpn_list_f;

   /* ************************************************************************************
   ||   FUNCTION         :  GET_LPN_INQUIRY_LIST_F                                      ||
   ||   Description      :  Function to get LPN inquiry list Details                    ||
   ||                                                                                   ||
   ||   VER     DATE            AUTHOR               MODIFICATION                       ||
   ||   -----   -------------   ----------------     -------------------                ||
   ||   1.0     15-OCT-2020     Mounika Parepalli     Initial version                   ||
   ||                                                                                   ||
   ***************************************************************************************/
   FUNCTION get_lpn_inquiry_det_list_f (p_lpn_number IN VARCHAR2)
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_number           NUMBER           := 0;
      l_procedure_name   VARCHAR2 (200)   := 'GET_LPN_INQUIRY_DET_LIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Start of the function',
                                   p_payload           => 'P_LPN_NUMBER'
                                  );
      vzero_qry := ' SELECT ''0'' FROM dual';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'select lpn.*,lpn1.license_plate_number outermost_lpn_number,lpn2.license_plate_number parent_lpn_number,wlc.inventory_item_id
                  ,msib.concatenated_segments item,trim (replace(replace(replace(replace (MSIB.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION,wlc.uom_code
                  ,wlc.secondary_uom_code,wlc.secondary_quantity,wlc.cost_group_id,wlc.quantity onhand_qty
                  ,XXALG_IM_ONHAND_DTLS_PKG.get_onhand_qty_f(WLC.INVENTORY_ITEM_ID,WLC.ORGANIZATION_ID,''AVAILABLE TO TRANSACT'') available_qty
                  ,msib1.concatenated_segments container,trim (replace(replace(replace(replace (MSIB1.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) CONTAINER_DESCRIPTION
                  ,(SELECT COST_GROUP_NAME FROM CSTBG_COST_GROUPS WHERE COST_GROUP_ID = WLC.COST_GROUP_ID) COST_GROUP_NAME
                  from (
                  select lpn_id, license_plate_number lpn_number ,outermost_lpn_id,parent_lpn_id,lpn.inventory_item_id container_id
                  ,lpn.subinventory_code,locator_id,lpn_context,lpn.organization_id,lpn.last_update_date,revision,lpn_state
                  gross_weight,gross_weight_uom_code,content_volume,content_volume_uom_code,container_volume,FLV.Meaning lpn_context_meaning,mp.organization_code,milk.concatenated_segments locator
                  ,container_volume_uom,tare_weight,tare_weight_uom_code,(NVL(CONTENT_VOLUME,0)+ NVL(CONTAINER_VOLUME,0))TOTAL_VOLUME,level
                  from wms_license_plate_numbers lpn,FND_LOOKUP_VALUES FLV,mtl_parameters mp,mtl_item_locations_kfv milk
                  where parent_lpn_id is not null
				 and  not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'')
				 AND FLV.Lookup_Code = to_char(lpn.LPN_Context) 
					 AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT''
                     AND FLV.language = userenv(''LANG'') 
                     AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE 
                     AND FLV.enabled_flag = ''Y''
					 and lpn.organization_id=mp.organization_id
					 and lpn.locator_id=milk.inventory_location_id(+)
                  --and organization_id = 7925
                  --start with parent_lpn_id = 7311--15541--15541
                  start with parent_lpn_id = (select lpn_id from wms_license_plate_numbers wlpn1 where wlpn1.license_plate_number='''
         || p_lpn_number
         || ''' )--15541--15541
                  connect by prior parent_lpn_id=lpn_Id)lpn, wms_license_plate_numbers lpn1,wms_license_plate_numbers lpn2
                  ,wms_lpn_contents wlc,mtl_system_items_b_kfv msib,mtl_system_items_b_kfv msib1
                  where lpn.outermost_lpn_id=lpn1.lpn_id(+)
                  and  lpn.parent_lpn_id = lpn2.lpn_id(+)
                  and lpn.lpn_id = wlc.parent_lpn_id(+)
                  and wlc.inventory_item_id = msib.inventory_item_id(+)
                  and wlc.organization_id = msib.organization_id(+)
                  and lpn.container_id = msib1.inventory_item_id(+)
                  and lpn.organization_id = msib1.organization_id(+)
                  union
                  select lpn.*,lpn1.license_plate_number outermost_lpn_number,lpn2.license_plate_number parent_lpn_number,wlc.inventory_item_id
                  ,msib.concatenated_segments item,trim (replace(replace(replace(replace (MSIB.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION,wlc.uom_code
                  ,wlc.secondary_uom_code,wlc.secondary_quantity,wlc.cost_group_id,wlc.quantity onhand_qty,wlc.quantity available_qty
                  ,msib1.concatenated_segments container,trim (replace(replace(replace(replace (MSIB1.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) CONTAINER_DESCRIPTION
                  ,(SELECT COST_GROUP_NAME FROM CSTBG_COST_GROUPS WHERE COST_GROUP_ID = WLC.COST_GROUP_ID) COST_GROUP_NAME
                  from (
                  select lpn_id, license_plate_number lpn_number ,outermost_lpn_id,parent_lpn_id,lpn.inventory_item_id container_id
                  ,lpn.subinventory_code,locator_id,lpn_context,lpn.organization_id,lpn.last_update_date,revision,lpn_state
                  gross_weight,gross_weight_uom_code,content_volume,content_volume_uom_code,container_volume,FLV.Meaning lpn_context_meaning,mp.organization_code,milk.concatenated_segments locator
                  ,container_volume_uom,tare_weight,tare_weight_uom_code,(NVL(CONTENT_VOLUME,0)+ NVL(CONTAINER_VOLUME,0))TOTAL_VOLUME,level
                  from wms_license_plate_numbers lpn,FND_LOOKUP_VALUES FLV,mtl_parameters mp,mtl_item_locations_kfv milk
				  where not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'')
				  AND FLV.Lookup_Code = to_char(lpn.LPN_Context) 
					 AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT''
                     AND FLV.language = userenv(''LANG'') 
                     AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE 
                     AND FLV.enabled_flag = ''Y''
					  and lpn.organization_id=mp.organization_id
					  and lpn.locator_id=milk.inventory_location_id(+)
                  --start with lpn_Id = 7311--15541--15541
                  start with lpn_Id = (select lpn_id from wms_license_plate_numbers wlpn1 where wlpn1.license_plate_number='''
         || p_lpn_number
         || ''' )
                  --and organization_id = 7925
                  connect by prior parent_lpn_id=lpn_Id)lpn, wms_license_plate_numbers lpn1,wms_license_plate_numbers lpn2
                  ,wms_lpn_contents wlc,mtl_system_items_b_kfv msib,mtl_system_items_b_kfv msib1
                  where lpn.outermost_lpn_id=lpn1.lpn_id(+)
                  and  lpn.parent_lpn_id = lpn2.lpn_id(+)
                  and lpn.lpn_id = wlc.parent_lpn_id(+)
                  and wlc.inventory_item_id = msib.inventory_item_id(+)
                  and wlc.organization_id = msib.organization_id(+)
                  and lpn.container_id = msib1.inventory_item_id(+)
                  and lpn.organization_id = msib1.organization_id(+)
				  ';
      -- AND LPN.ORGANIZATION_ID =  '|| P_ORGANIZATION_ID  ||'
      -- AND LPN.LICENSE_PLATE_NUMBER =  '''|| P_LPN_NUMBER ||'''';
      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         x_clob := '{"Status": "Invalid LPN"}';
         xxprop_common_util_pkg.trace_log
                            (p_module            =>    g_package_name
                                                    || '.'
                                                    || l_procedure_name,
                             p_message_text      => 'ERROR',
                             p_payload           => 'NO_DATA_FOUND in LPNInquiry Query'
                            );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
                                   (p_module            =>    g_package_name
                                                           || '.'
                                                           || l_procedure_name,
                                    p_message_text      => 'After executing query',
                                    p_payload           => x_clob
                                   );
      RETURN x_clob;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_LPN_INQUIRY_LIST_F: Error Message While Retreving Operating Unit Details as: '
             || SQLERRM
            );
         RETURN x_return_zero;
   END get_lpn_inquiry_det_list_f;

   FUNCTION get_lpn_inquiry_list_f (p_lpn_number IN VARCHAR2)
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_number           NUMBER           := 0;
      l_procedure_name   VARCHAR2 (200)   := 'GET_LPN_INQUIRY_LIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Start of the function',
                                   p_payload           => 'P_LPN_NUMBER'
                                  );
      vzero_qry := ' SELECT ''0'' FROM dual';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'select wlpn.LPN_ID,wlpn.license_plate_number LPN_NUMBER,wlpn.OUTERMOST_LPN_ID,wlpn.PARENT_LPN_ID,wlpn.SUBINVENTORY_CODE,wlpn.LOCATOR_ID,wlpn.LPN_CONTEXT,
wlpn.ORGANIZATION_ID,wlpn.LAST_UPDATE_DATE
,wlpn.REVISION,wlpn.GROSS_WEIGHT,wlpn.GROSS_WEIGHT_UOM_CODE,wlpn.CONTENT_VOLUME,wlpn.CONTENT_VOLUME_UOM_CODE,wlpn.CONTAINER_VOLUME,
flv.meaning LPN_CONTEXT_MEANING
,mp.ORGANIZATION_CODE, milk.concatenated_segments LOCATOR,wlpn.CONTAINER_VOLUME_UOM,wlpn.TARE_WEIGHT,wlpn.TARE_WEIGHT_UOM_CODE
,(NVL(wlpn.CONTENT_VOLUME,0)+ NVL(wlpn.CONTAINER_VOLUME,0)) TOTAL_VOLUME,null LEVEL1,null OUTERMOST_LPN_NUMBER,null PARENT_LPN_NUMBER,wlc.INVENTORY_ITEM_ID
,msib.concatenated_segments item,trim (REGEXP_REPLACE(MSIB.description,''[^A-Z0-9a-z ]'') ) ITEM_DESCRIPTION,wlc.uom_code
,wlc.secondary_uom_code,wlc.secondary_quantity,wlc.cost_group_id,wlc.quantity onhand_qty
                  ,null available_qty
				  ,null container,null CONTAINER_DESCRIPTION,ccg.COST_GROUP_NAME 
 from wms_license_plate_numbers wlpn,FND_LOOKUP_VALUES FLV,mtl_parameters mp,mtl_item_locations_kfv milk,wms_lpn_contents wlc,mtl_system_items_b_kfv msib
 ,CSTBG_COST_GROUPS ccg
 where  FLV.Lookup_Code = to_char(wlpn.LPN_Context) 
					 AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT''
                     AND FLV.language = userenv(''LANG'') 
                     AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE 
                     AND FLV.enabled_flag = ''Y''
					 and wlpn.ORGANIZATION_id=mp.organization_id
					 and wlpn.locator_id=milk.inventory_location_id(+)
					 and wlpn.lpn_id = wlc.parent_lpn_id(+)
					 and wlc.inventory_item_id = msib.inventory_item_id(+)
                  and wlc.organization_id = msib.organization_id(+)
				  and WLC.COST_GROUP_ID=ccg.COST_GROUP_ID(+)
				  and wlpn.license_plate_number='''
         || p_lpn_number
         || ''' 
				  and not REGEXP_LIKE (wlpn.License_Plate_Number, ''[^A-Z0-9a-z ]'')
				  ';
      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         x_clob := '{"Status": "Invalid LPN"}';
         xxprop_common_util_pkg.trace_log
                            (p_module            =>    g_package_name
                                                    || '.'
                                                    || l_procedure_name,
                             p_message_text      => 'ERROR',
                             p_payload           => 'NO_DATA_FOUND in LPNInquiry Query'
                            );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
                                   (p_module            =>    g_package_name
                                                           || '.'
                                                           || l_procedure_name,
                                    p_message_text      => 'After executing query',
                                    p_payload           => x_clob
                                   );
      RETURN x_clob;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_LPN_INQUIRY_LIST_F: Error Message While Retreving Operating Unit Details as: '
             || SQLERRM
            );
         RETURN x_return_zero;
   END get_lpn_inquiry_list_f;

   /* ************************************************************************************
   ||   FUNCTION         :  GET_PACK_LPN_LIST_F                                        ||
   ||   Description      :  Function to get LPN Details of the PACK LPN                 ||
   ||                                                                                   ||
   ||   VER     DATE            AUTHOR               MODIFICATION                       ||
   ||   -----   -------------   ----------------     -------------------                ||
   ||   1.0     10-FEB-2020     Satish Addala         Initial version                   ||
   ||                                                                                   ||
   ***************************************************************************************/
   FUNCTION get_pack_lpn_list_f (
      p_organization_id   IN   NUMBER,
      p_last_refresh      IN   VARCHAR2,
      p_full_refresh      IN   CHAR DEFAULT 'N'
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_PACK_LPN_LIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'lpn.LPN_ID, lpn.License_Plate_Number LPN_Number, lpn.Inventory_Item_ID Inventory_ID,'
         || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID, lpn.LPN_Context,lpn.Organization_id,'
         || 'msi.primary_uom_code primary_uom,wlc.secondary_uom_code secondary_uom,wlc.secondary_quantity, '
         || 'lpn.LAST_UPDATE_DATE,lpn.REVISION,lpn.Outermost_LPN_ID,msi.Concatenated_Segments Items,mil.Concatenated_Segments Locators,FLV.Meaning '
         || ',NULL PackQty,NULL DATA_RECORD_FLAG '
         || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV,WMS_LPN_CONTENTS WLC '
         || 'WHERE lpn.Organization_ID = msi.Organization_ID (+) '
         || 'AND lpn.Organization_ID   = mil.Organization_ID (+) '
         || 'AND lpn.Organization_ID   = '
         || p_organization_id
         || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID(+) '
         || 'and trunc(lpn.last_update_date) between  trunc(sysdate)-30 and  trunc(sysdate ) '
         || 'AND lpn.Inventory_Item_id = msi.Inventory_Item_id (+) '
         || 'AND lpn.locator_id        = mil.inventory_location_id (+) '
         || 'AND FLV.Lookup_Code        = lpn.LPN_Context '
         || 'AND FLV.Lookup_Type        = ''WMS_LPN_CONTEXT'' '
         || 'AND FLV.language = userenv(''LANG'') '
         || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
         || 'AND FLV.enabled_flag = ''Y'' '
         || 'AND lpn.LPN_Context IN (1,5) and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') ';

      IF p_full_refresh = 'N'
      THEN
         v_qry :=
               v_qry
            || 'AND lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')';
         v_qry :=
               v_qry
            || 'UNION SELECT lpn.LPN_ID, lpn.License_Plate_Number LPN_Number, lpn.Inventory_Item_ID Inventory_ID,'
            || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID, lpn.Parent_LPN_ID, lpn.LPN_Context,lpn.Organization_id,'
            || 'msi.primary_uom_code primary_uom,wlc.secondary_uom_code secondary_uom,wlc.secondary_quantity, '
            || 'lpn.LAST_UPDATE_DATE,lpn.REVISION,lpn.Outermost_LPN_ID, msi.Concatenated_Segments Items,mil.Concatenated_Segments Locators,FLV.Meaning '
            || ',NULL PackQty,''D'' DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV,WMS_LPN_CONTENTS WLC '
            || 'WHERE lpn.Organization_ID = msi.Organization_ID (+) '
            || 'AND lpn.Organization_ID   = mil.Organization_ID (+) '
            || 'AND lpn.Organization_ID   = '
            || p_organization_id
            || 'AND LPN.LPN_ID = WLC.PARENT_LPN_ID(+) '
            || 'AND lpn.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 'AND lpn.locator_id        = mil.inventory_location_id (+) '
            || 'AND FLV.Lookup_Code        = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type        = ''WMS_LPN_CONTEXT'' '
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' '
            || 'AND lpn.LPN_Context NOT IN (1,5) and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
            || 'AND lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')';
         v_qry := 'SELECT  DISTINCT ' || v_qry;
      ELSE
         v_qry := 'SELECT DISTINCT ' || v_qry;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
                         (p_module            =>    g_package_name
                                                 || '.'
                                                 || l_procedure_name,
                          p_message_text      => 'ERROR',
                          p_payload           => 'NO_DATA_FOUND in LPNs for Pack Query'
                         );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
                                   (p_module            =>    g_package_name
                                                           || '.'
                                                           || l_procedure_name,
                                    p_message_text      => 'After executing query',
                                    p_payload           => x_clob
                                   );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_PACK_LPN_LIST_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   END get_pack_lpn_list_f;

   /* ************************************************************************************
   ||   FUNCTION         :  GET_UNPACK_LPN_DETAIL_F                                    ||
   ||   Description      :  Function to get LPN Details of the UNPACK LPN               ||
   ||                                                                                   ||
   ||   VER     DATE            AUTHOR               MODIFICATION                       ||
   ||   -----   -------------   ----------------     -------------------                ||
   ||   1.0     10-FEB-2020     Satish Addala         Initial version                   ||
   ||                                                                                   ||
   ***************************************************************************************/
   FUNCTION get_unpack_lpn_list_f (
      p_organization_id   IN   NUMBER,
      p_last_refresh      IN   VARCHAR2,
      p_full_refresh      IN   CHAR DEFAULT 'N'
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_UNPACK_LPN_LIST_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,WLC.Inventory_Item_ID Inventory_item_id, '
         || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,trim (replace(replace(replace(replace (msi.description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION '
         || ',lpn.LPN_Context,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.Outermost_LPN_ID,MSI.Concatenated_Segments Item, '
         || 'msi.primary_uom_code uom_code,mil.Concatenated_Segments Locators,WLC.LOT_NUMBER, '
         || 'WLC.QUANTITY PACKED_QUANTITY,NULL UnPackQty,NULL DATA_RECORD_FLAG '
         || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV '
         || ',wms_lpn_contents WLC '
         || 'WHERE lpn.Organization_ID = mil.Organization_ID  '
         || 'AND WLC.Organization_ID = msi.Organization_ID (+) '
         || 'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) 'xczczc
         || 'AND lpn.locator_id = mil.inventory_location_id (+) '
         || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
         || 
            -- 'and trunc(lpn.last_update_date) between  trunc(sysdate)-365 and  trunc(sysdate ) '||
            'AND LPN.LPN_ID = WLC.PARENT_LPN_ID '
         || 'AND FLV.Lookup_Code = lpn.LPN_Context '
         || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
         || 'AND LPN.LPN_Context IN (1) '
         || 'AND FLV.language = userenv(''LANG'') '
         || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
         || 'AND FLV.enabled_flag = ''Y'' and not REGEXP_LIKE (lpn.License_Plate_Number, ''[^A-Z0-9a-z ]'') '
         || 'AND lpn.Organization_ID = '
         || p_organization_id;

      IF p_full_refresh = 'N'
      THEN
         v_qry :=
               v_qry
            || 'AND ((lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) '
            || 'OR (WLC.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS''))) ';
        /* v_qry :=
               v_qry
            || 'UNION SELECT lpn.LPN_ID,lpn.License_Plate_Number LPN_Number,NULL Inventory_item_id, '
            || 'lpn.Subinventory_Code Subinventory_Code,lpn.Locator_ID,lpn.Parent_LPN_ID,NULL ITEM_DESCRIPTION '
            || ',lpn.LPN_Context,lpn.Organization_id,lpn.LAST_UPDATE_DATE,lpn.Outermost_LPN_ID,NULL Item, '
            || 'msi.primary_uom_code uom_code,mil.Concatenated_Segments Locators,WLC.LOT_NUMBER,NULL PACKED_QUANTITY,NULL UnPackQty,''D'' DATA_RECORD_FLAG '
            || 'FROM WMS_LICENSE_PLATE_NUMBERS lpn,MTL_SYSTEM_ITEMS_KFV msi,MTL_ITEM_LOCATIONS_KFV mil,FND_LOOKUP_VALUES FLV,wms_lpn_contents wlc  '
            || 'WHERE lpn.Organization_ID = mil.Organization_ID (+) '
            || 'AND lpn.locator_id = mil.inventory_location_id (+) '
            || 'AND WLC.Inventory_Item_id = msi.Inventory_Item_id (+) '
            || 
               --'AND WLC.Organization_ID = msi.Organization_ID (+) ' ||
               'AND LPN.LPN_ID = WLC.PARENT_LPN_ID '
            || 
               ---'AND LPN.ORGANIZATION_ID  = WLC.ORGANIZATION_ID (+) ' ||
               'AND FLV.Lookup_Code = lpn.LPN_Context '
            || 'AND FLV.Lookup_Type = ''WMS_LPN_CONTEXT'' '
            || 'AND lpn.Organization_ID = '
            || p_organization_id
            || 'AND FLV.language = userenv(''LANG'') '
            || 'AND LPN.LPN_Context NOT IN (1,4) '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' '
            || 'AND (lpn.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'')) ';*/
         v_qry := 'SELECT  DISTINCT ' || v_qry;
      ELSE
         v_qry := 'SELECT DISTINCT ' || v_qry;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
                       (p_module            =>    g_package_name
                                               || '.'
                                               || l_procedure_name,
                        p_message_text      => 'ERROR',
                        p_payload           => 'NO_DATA_FOUND in LPNs for UnPack Query'
                       );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
                                   (p_module            =>    g_package_name
                                                           || '.'
                                                           || l_procedure_name,
                                    p_message_text      => 'After executing query',
                                    p_payload           => x_clob
                                   );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_UNPACK_LPN_LIST_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   END get_unpack_lpn_list_f;

   /* ************************************************************************************
     ||   FUNCTION         :  GET_SHIP_LPNS_F                                             ||
     ||   Description      :  Function to get Ship LPNs                                   ||
     ||                                                                                   ||
     ||   VER     DATE            AUTHOR               MODIFICATION                       ||
     ||   -----   -------------   ----------------     -------------------                ||
     ||   1.0     22-DEC-2020    Mounika parepalli         Initial version                ||
     ||                                                                                   ||
     ***************************************************************************************/
   FUNCTION get_ship_lpns_f (
      p_organization_id   IN   NUMBER,
      p_last_refresh      IN   VARCHAR2,
      p_full_refresh      IN   CHAR DEFAULT 'N'
   )
      RETURN CLOB
   AS
      v_qry              VARCHAR2 (32000);
      x_clob             CLOB;
      x_return_zero      CLOB;
      vzero_qry          VARCHAR2 (1000);
      l_procedure_name   VARCHAR2 (200)   := 'GET_SHIP_LPNS_F';
   BEGIN
      xxprop_common_util_pkg.trace_log
              (p_module            => g_package_name || '.'
                                      || l_procedure_name,
               p_message_text      => 'Start of the function',
               p_payload           => 'P_ORGANIZATION_ID,P_LAST_REFRESH,P_FULL_REFRESH'
              );
      vzero_qry := ' SELECT ''0'' MESSAGE FROM DUAL';
      x_return_zero :=
                   xxprop_common_util_pkg.get_json_with_metadata_f (vzero_qry);
      v_qry :=
            'WDD.DELIVERY_DETAIL_ID DETAIL_ID,WND.DELIVERY_ID DELIVERY_ID,WND.NAME DELIVERY_NAME,WND.DELIVERED_DATE '
         || ',WDD.SOURCE_HEADER_NUMBER SO_NUMBER,AR.CUSTOMER_NAME,TO_CHAR(WDD.LAST_UPDATE_DATE,''DD-MM-YYYY HH24:MI:SS'') LAST_UPDATE_DATE '
         || ',WDD.INVENTORY_ITEM_ID ITEM_ID,MSIB.CONCATENATED_SEGMENTS ITEM,trim (replace(replace(replace(replace (WDD.item_description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION,MSIB.PRIMARY_UOM_CODE UOM '
         || ',MSIB.PRIMARY_UNIT_OF_MEASURE UOM_DESC,MTRL.SECONDARY_UOM_CODE SECONDARY_UOM,WDD.SHIP_FROM_LOCATION_ID '
         || ',MTRL.SECONDARY_QUANTITY,MTRL.SECONDARY_QUANTITY_DELIVERED,MTRL.SECONDARY_QUANTITY_DETAILED,SECONDARY_REQUIRED_QUANTITY '
         || ',(SELECT LOCATION_CODE||'':''||ADDRESS_LINE_1||''-''||ADDRESS_LINE_2||''-''||REGION_1||''-''||REGION_2||''-''||POSTAL_CODE||''-''||COUNTRY '
         || 'FROM HR_LOCATIONS WHERE WDD.SHIP_FROM_LOCATION_ID = LOCATION_ID) SHIP_FROM_LOCATION,WDD.SHIP_TO_LOCATION_ID '
         || ',(SELECT ORIG_SYSTEM_REFERENCE||'':''||ADDRESS1||''-----''||COUNTRY '
         || 'FROM HZ_LOCATIONS WHERE WDD.SHIP_TO_LOCATION_ID = LOCATION_ID )SHIP_TO_LOCATION,WDD.DELIVER_TO_LOCATION_ID '
         || ',(SELECT ORIG_SYSTEM_REFERENCE||'':''||ADDRESS1||''-----''||COUNTRY '
         || 'FROM HZ_LOCATIONS WHERE WDD.SHIP_TO_LOCATION_ID = LOCATION_ID )DELIVER_TO_LOCATION,WDD.SUBINVENTORY '
         || ',WDD.LOCATOR_ID,MILK.CONCATENATED_SEGMENTS LOCATOR,WDD.REQUESTED_QUANTITY,WDD.SHIPPED_QUANTITY '
         || ',WDD.ORGANIZATION_ID,MTRH.REQUEST_NUMBER MOVE_ORDER_NUMBER,MTRL.LINE_ID MO_LINE_ID,MTRL.LINE_NUMBER MO_LINE_NUM '
         || ',WDD.RELEASED_STATUS LINE_STATUS_ID,FLV.MEANING LINE_STATUS,WDD.LPN_ID '
         || ',WDD.FREIGHT_TERMS_CODE,WDD.FOB_CODE FOB,OOD.ORGANIZATION_CODE '
         || ',WDD.SHIP_METHOD_CODE,WDD.CARRIER_ID,WDD.SERVICE_LEVEL,WDD.MODE_OF_TRANSPORT,NULL DATA_RECORD_FLAG '
         || 'FROM WSH_NEW_DELIVERIES WND,WSH_DELIVERY_DETAILS WDD,MTL_SYSTEM_ITEMS_B_KFV MSIB '
         || ',WSH_DELIVERY_ASSIGNMENTS WDA,AR_CUSTOMERS AR,ORG_ORGANIZATION_DEFINITIONS OOD '
         || ',MTL_ITEM_LOCATIONS_KFV MILK,MTL_TXN_REQUEST_HEADERS MTRH,MTL_TXN_REQUEST_LINES MTRL '
         || ',FND_LOOKUP_VALUES FLV '
         || 'WHERE MSIB.INVENTORY_ITEM_ID = WDD.INVENTORY_ITEM_ID '
         || 'AND MSIB.ORGANIZATION_ID = WDD.ORGANIZATION_ID '
         || 'AND WDD.ORGANIZATION_ID = OOD.ORGANIZATION_ID '
         || 'AND MTRL.ORGANIZATION_ID = WDD.ORGANIZATION_ID '
         || 'AND WDA.DELIVERY_ID = WND.DELIVERY_ID '
         || 'AND WDA.DELIVERY_DETAIL_ID = WDD.DELIVERY_DETAIL_ID '
         || 'AND WDD.LOCATOR_ID = MILK.INVENTORY_LOCATION_ID '
         || 'AND MTRH.HEADER_ID = MTRL.HEADER_ID '
         || 'AND WDD.CUSTOMER_ID = AR.CUSTOMER_ID '
         || 'AND WDD.MOVE_ORDER_LINE_ID= MTRL.LINE_ID '
         || 'AND WDD.RELEASED_STATUS = FLV.LOOKUP_CODE AND FLV.LOOKUP_TYPE = ''FTE_MLS_LINE_STATUS_DISPLAY'' '
         || 'AND WDD.RELEASED_STATUS IN (''Y'') '
         || 'AND FLV.LANGUAGE = USERENV(''LANG'') '
         || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
         || 'AND FLV.enabled_flag = ''Y'' '
         || 'AND WDD.ORGANIZATION_ID =  '
         || p_organization_id;

      IF p_full_refresh = 'N'
      THEN
         v_qry :=
               v_qry
            || 'AND WDD.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'') ';
         v_qry :=
               v_qry
            || 'UNION SELECT WDD.DELIVERY_DETAIL_ID DETAIL_ID,WND.DELIVERY_ID DELIVERY_ID,WND.NAME DELIVERY_NAME,WND.DELIVERED_DATE '
            || ',WDD.SOURCE_HEADER_NUMBER SO_NUMBER,AR.CUSTOMER_NAME,TO_CHAR(WDD.LAST_UPDATE_DATE,''DD-MM-YYYY HH24:MI:SS'') LAST_UPDATE_DATE '
            || ',WDD.INVENTORY_ITEM_ID ITEM_ID,MSIB.CONCATENATED_SEGMENTS ITEM,trim (replace(replace(replace(replace (WDD.item_description,''"'',''- inch''),chr(10),''''),chr(13),''''),chr(9),'''') ) ITEM_DESCRIPTION,MSIB.PRIMARY_UOM_CODE UOM '
            || ',MSIB.PRIMARY_UNIT_OF_MEASURE UOM_DESC,MTRL.SECONDARY_UOM_CODE SECONDARY_UOM,WDD.SHIP_FROM_LOCATION_ID '
            || ',MTRL.SECONDARY_QUANTITY,MTRL.SECONDARY_QUANTITY_DELIVERED,MTRL.SECONDARY_QUANTITY_DETAILED,SECONDARY_REQUIRED_QUANTITY '
            || ',(SELECT LOCATION_CODE||'':''||ADDRESS_LINE_1||''-''||ADDRESS_LINE_2||''-''||REGION_1||''-''||REGION_2||''-''||POSTAL_CODE||''-''||COUNTRY '
            || 'FROM HR_LOCATIONS WHERE WDD.SHIP_FROM_LOCATION_ID = LOCATION_ID) SHIP_FROM_LOCATION,WDD.SHIP_TO_LOCATION_ID '
            || ',(SELECT ORIG_SYSTEM_REFERENCE||'':''||ADDRESS1||''-----''||COUNTRY '
            || 'FROM HZ_LOCATIONS WHERE WDD.SHIP_TO_LOCATION_ID = LOCATION_ID )SHIP_TO_LOCATION,WDD.DELIVER_TO_LOCATION_ID '
            || ',(SELECT ORIG_SYSTEM_REFERENCE||'':''||ADDRESS1||''-----''||COUNTRY '
            || 'FROM HZ_LOCATIONS WHERE WDD.SHIP_TO_LOCATION_ID = LOCATION_ID )DELIVER_TO_LOCATION,WDD.SUBINVENTORY '
            || ',WDD.LOCATOR_ID,MILK.CONCATENATED_SEGMENTS LOCATOR,WDD.REQUESTED_QUANTITY,WDD.SHIPPED_QUANTITY '
            || ',WDD.ORGANIZATION_ID,MTRH.REQUEST_NUMBER MOVE_ORDER_NUMBER,MTRL.LINE_ID MO_LINE_ID,MTRL.LINE_NUMBER MO_LINE_NUM '
            || ',WDD.RELEASED_STATUS LINE_STATUS_ID,FLV.MEANING LINE_STATUS,WDD.LPN_ID '
            || ',WDD.FREIGHT_TERMS_CODE,WDD.FOB_CODE FOB,OOD.ORGANIZATION_CODE '
            || ',WDD.SHIP_METHOD_CODE,WDD.CARRIER_ID,WDD.SERVICE_LEVEL,WDD.MODE_OF_TRANSPORT,''D'' DATA_RECORD_FLAG '
            || 'FROM WSH_NEW_DELIVERIES WND,WSH_DELIVERY_DETAILS WDD,MTL_SYSTEM_ITEMS_B_KFV MSIB '
            || ',WSH_DELIVERY_ASSIGNMENTS WDA,AR_CUSTOMERS AR,ORG_ORGANIZATION_DEFINITIONS OOD '
            || ',MTL_ITEM_LOCATIONS_KFV MILK,MTL_TXN_REQUEST_HEADERS MTRH,MTL_TXN_REQUEST_LINES MTRL '
            || ',FND_LOOKUP_VALUES FLV '
            || 'WHERE MSIB.INVENTORY_ITEM_ID = WDD.INVENTORY_ITEM_ID '
            || 'AND MSIB.ORGANIZATION_ID = WDD.ORGANIZATION_ID '
            || 'AND WDD.ORGANIZATION_ID = OOD.ORGANIZATION_ID '
            || 'AND MTRL.ORGANIZATION_ID = WDD.ORGANIZATION_ID '
            || 'AND WDA.DELIVERY_ID = WND.DELIVERY_ID '
            || 'AND WDA.DELIVERY_DETAIL_ID = WDD.DELIVERY_DETAIL_ID '
            || 'AND WDD.LOCATOR_ID = MILK.INVENTORY_LOCATION_ID '
            || 'AND MTRH.HEADER_ID = MTRL.HEADER_ID '
            || 'AND WDD.CUSTOMER_ID = AR.CUSTOMER_ID '
            || 'AND WDD.MOVE_ORDER_LINE_ID= MTRL.LINE_ID '
            || 'AND WDD.RELEASED_STATUS = FLV.LOOKUP_CODE AND FLV.LOOKUP_TYPE = ''FTE_MLS_LINE_STATUS_DISPLAY'' '
            || 'AND WDD.RELEASED_STATUS NOT IN (''Y'') '
            || 'AND FLV.LANGUAGE = USERENV(''LANG'') '
            || 'AND NVL(FLV.end_date_active,sysdate+1) > SYSDATE '
            || 'AND FLV.enabled_flag = ''Y'' '
            || 'AND WDD.ORGANIZATION_ID =  '
            || p_organization_id
            || 'AND WDD.last_update_date >= TO_DATE('''
            || p_last_refresh
            || ''', ''DD-MON-RRRR HH24:MI:SS'') ';zxczc
         v_qry := 'SELECT  DISTINCT ' || v_qry;
      ELSE
         v_qry := 'SELECT DISTINCT ' || v_qry;
      END IF;

      xxprop_common_util_pkg.trace_log
                                  (p_module            =>    g_package_name
                                                          || '.'
                                                          || l_procedure_name,
                                   p_message_text      => 'Before executing query',
                                   p_payload           => v_qry
                                  );
      x_clob := xxprop_common_util_pkg.get_json_with_metadata_f (v_qry);

      IF x_clob IS NULL
      THEN
         xxprop_common_util_pkg.trace_log
                              (p_module            =>    g_package_name
                                                      || '.'
                                                      || l_procedure_name,
                               p_message_text      => 'ERROR',
                               p_payload           => 'NO_DATA_FOUND in ShipLPNs Query'
                              );
         RETURN x_clob;
      END IF;

      xxprop_common_util_pkg.trace_log
                                   (p_module            =>    g_package_name
                                                           || '.'
                                                           || l_procedure_name,
                                    p_message_text      => 'After executing query',
                                    p_payload           => x_clob
                                   );
      RETURN x_clob;
      DBMS_LOB.freetemporary (x_clob);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_clob := 'NO DATA FOUND';
         RETURN x_clob;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
            (   'GET_SHIP_LPNS_F: Error Message While Retreving  Details as: '
             || SQLERRM
            );
         RETURN SQLERRM;
   /*IF  X_CLOB IS NULL THEN
      RETURN x_return_zero;
   ELSE
      RETURN X_CLOB;
   END IF; */
   END get_ship_lpns_f;
END xxalg_all_lpn_lists_pkg;
/

