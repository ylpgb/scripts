"""
Module Name: bm_config.py
Author: Leipo Yan

License: This work is licensed under a Creative Commons Attribution-NonCommercial
4.0 International License.
For more information, visit https://creativecommons.org/licenses/by-nc/4.0/
"""

"""
This module extracts the BM configuration from the Excel file and stores the extracted
configuration in DataFrames.

Configuration settings can be found in the "System Defaults" sheet of the Excel file.

It works with BM config version starting from V7.03 onwards.
"""

import xlwings as xw
import pandas as pd
from dataclasses import dataclass, make_dataclass

def create_value_to_name_map(cls):
    return {v: k for k, v in vars(cls).items() if not k.startswith('_') and not callable(v)}

def get_name(cls, value):
    value_to_name = create_value_to_name_map(cls)
    return value_to_name.get(value, "Unknown value")

def get_value(cls, name):
    return getattr(cls, name, "Unknown name")

class Model:
    ETH = 1
    PON = 2
    CABLE = 3

    @classmethod
    def iterate(cls):
        for name, value in cls.__dict__.items():
            if isinstance(value, int) and not name.startswith('__'):
                yield name, value
                
class ModelConfig:
    ETH_2GB_GW_WAVE6X4 = 1
    ETH_2GB_GW_WAVE700 = 2
    ETH_1GB_GW_WAVE6X4 = 3
    PON_2GB_GW_WAVE6X4 = 4
    PON_2GB_GW_WAVE700 = 5
    PON_1GB_GW_WAVE6X4 = 6
    CABLE_2GB_GW_WAVE700 = 7
    CABLE_1GB_MODEM = 8

    @classmethod
    def iterate(cls):
        for name, value in cls.__dict__.items():
            if isinstance(value, int) and not name.startswith('__'):
                yield name, value

    @classmethod
    def model(cls, config):
        # check if config is a value
        if isinstance(config, int):
            name = get_name(cls, config)
            if name.startswith("ETH"):
                return Model.ETH
            elif name.startswith("PON"):
                return Model.PON
            elif name.startswith("CABLE"):
                return Model.CABLE
        else:
            raise ValueError("Invalid config type")

    @classmethod
    def config_cnt(cls):
        return len([name for name in dir(cls) if not name.startswith('__')])

class DFType:
    POOL = 1
    POLICY = 2
    GENPOOL = 3
    LINUXCMA = 4

    @classmethod
    def iterate(cls):
        for name, value in cls.__dict__.items():
            if isinstance(value, int) and not name.startswith('__'):
                yield name, value

def create_model_bm_config_class():
    fields = [(name.lower() + '_df', pd.DataFrame) for name, _ in DFType.iterate()]
    return make_dataclass('ModelBMConfig', fields)

ModelBMConfig = create_model_bm_config_class()

@dataclass
class ModelConfigParams:
    cell_lgm_system: str
    cell_ddr_size: str
    cell_subsystem: str
    cell_imix_dis_model: str
    cell_wav614_num: str
    cell_wav614_desc: str
    cell_wav624_num: str
    cell_wav624_desc: str
    cell_wav700_num: str
    cell_wav700_desc: str

@dataclass
class DFTypeParams:
    type: DFType
    cell_start: str
    cell_end: str
    header: int
    filter_col_idx: int

class BMConfig:
    def __init__(self, file_path, search_start_cell=False):
        self.file_path = file_path
        self.search_start_cell = search_start_cell

        # Variables to be populated
        self.app = None
        self.wb = None
        self.sheet = None
        self.revision = None
        self.model_config_params = {}
        self.model_config_params_cells = None
        self.dftype_params = {}
        self.bm_config = {}
        
		# Constants
        self.sheet_bm_allocation = 'BM Allocation'
        self.sheet_rev_hist = 'Revision Hist'
        self.const_system_eth = 'Telco_EthWAN_DSL'
        self.const_system_pon = 'Telco_PON_DSL'
        self.const_system_cable = 'Cable_DocSIS'

        self.cell_revision = 'C1'
        
        self.cell_lgm_system = 'C5'
        self.cell_ddr_size = 'C6'
        self.cell_subsystem = 'C7'
        self.cell_imix_dis_model = 'C8'
        self.cell_wav614_num = 'C18'
        self.cell_wav614_desc = 'C19'
        self.cell_wav624_num = 'C20'
        self.cell_wav624_desc = 'C21'
        self.cell_wav700_num = 'C24'
        self.cell_wav700_desc = 'C25'

    def __enter__(self):
        try:
            self.load_file()
        except Exception as e:
            print(f"Failed to load file: {e}")
            self.cleanup()
            raise
        return self

    def cleanup(self):
        """Cleanup resources"""
        if self.wb:
            self.wb.close()
        if self.app:
            self.app.kill()
        self.wb = None
        self.app = None
    
    def __exit__(self, exc_type, exc_value, traceback):
        self.cleanup()
        
    def load_file(self):
        """Load the Excel file"""

        try:
            self.app = xw.App(visible=False)  # Set to False to run Excel in the background
            self.wb = self.app.books.open(self.file_path)
            self.sheet = self.wb.sheets[self.sheet_bm_allocation]
        except Exception as e:
            print(f"An unexpected error when trying to open the Excel file.")
            self.cleanup()
            raise

    def get_revision(self):
        """Get the revision number from the Excel file"""

        sheet = self.wb.sheets[self.sheet_rev_hist]
        if not sheet:
            self.revision = None
        else:
            self.revision = sheet.range(self.cell_revision).expand('down').value[-1]

    def find_start_cell(self, search_value, search_range='A50:P100'):
        """Find a cell with the specified search value within the given range"""

        cell = self.sheet.range(search_range).api.Find(search_value, LookIn=xw.constants.FindLookIn.xlValues)
        if cell:
            # cell_address = cell.Address.replace('$', '') # Remove '$' to convert to 'B60' format 
            # return cell_address
            return self.sheet.range(cell.Address)
        else:
            print("Start cell with value '{}' not found".format(search_value))
            raise ValueError

    def get_end_cell(self, start_cell, row_offset, column_offset):
        """Get the cell that is row_offset rows and column_offset columns from start_address"""

        return start_cell.offset(row_offset, column_offset)

    def set_model_config_params_cells(self):
        """Create the model configuration parameters cells"""

        self.model_config_params_cells = ModelConfigParams(self.cell_lgm_system, self.cell_ddr_size, self.cell_subsystem, self.cell_imix_dis_model, self.cell_wav614_num, self.cell_wav614_desc, self.cell_wav624_num, self.cell_wav624_desc, self.cell_wav700_num, self.cell_wav700_desc)

    def set_model_config_params(self):
        """Create the model configuration parameters"""

        # For the numer of elements in ModelConfig, create a ModelConfigParams object
        for name, value in ModelConfig.iterate():
            match value:
                case ModelConfig.ETH_2GB_GW_WAVE6X4:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_eth, '2048', 'Gateway', 'Telco', '1', '10000', '2', '20000', '0', '80000')
                case ModelConfig.ETH_2GB_GW_WAVE700:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_eth, '2048', 'Gateway', 'Telco', '0', '80000', '0', '80000', '1', '80000')
                case ModelConfig.ETH_1GB_GW_WAVE6X4:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_eth, '1024', 'Gateway', 'Telco', '1', '5000', '2', '10000', '0', '80000')
                case ModelConfig.PON_2GB_GW_WAVE6X4:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_pon, '2048', 'Gateway', 'Telco', '1', '10000', '2', '20000', '0', '80000')
                case ModelConfig.PON_2GB_GW_WAVE700:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_pon, '2048', 'Gateway', 'Telco', '0', '80000', '0', '80000', '1', '80000')
                case ModelConfig.PON_1GB_GW_WAVE6X4:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_pon, '1024', 'Gateway', 'Telco', '1', '5000', '2', '10000', '0', '80000')
                case ModelConfig.CABLE_2GB_GW_WAVE700:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_cable, '2048', 'Gateway', 'AVM Captures', '0', '10000', '0', '20000', '1', '80000')
                case ModelConfig.CABLE_1GB_MODEM:
                    self.model_config_params[value] = ModelConfigParams(self.const_system_cable, '1024', 'Modem', 'AVM Captures', '0', '10000', '0', '20000', '0', '80000')

    def set_dftype_params(self):
        '''Create the DataFrame type parameters, which will be used to filter the extracted data'''

        # It takes long time for xlwings to search for the cell based on cell value. So, hardcode the cell address here.
        if self.search_start_cell:
            for name, value in DFType.iterate():
                match value:
                    case DFType.POOL:
                        start_cell = self.find_start_cell('PoolId')
                        end_cell = self.get_end_cell(start_cell, 11, 2)
                        self.dftype_params[value] = DFTypeParams(DFType.POOL, start_cell.get_address(), end_cell.get_address(), 1, 2) # Header is 1
                    case DFType.POLICY:
                        start_cell = self.find_start_cell('Resource Tag')
                        end_cell = self.get_end_cell(start_cell, 32, 4)
                        self.dftype_params[value] = DFTypeParams(DFType.POLICY, start_cell.get_address(), end_cell.get_address(), 1, 3) # Header is 1
                    case DFType.GENPOOL:
                        start_cell = self.find_start_cell('GenPool Type')
                        end_cell = self.get_end_cell(start_cell, 5, 1)
                        self.dftype_params[value] = DFTypeParams(DFType.GENPOOL, start_cell.get_address(), end_cell.get_address(), 1, 1) # Header is 1
                    case DFType.LINUXCMA:
                        start_cell = self.find_start_cell('Total CMA ')
                        end_cell = self.get_end_cell(start_cell, 0, 1)
                        self.dftype_params[value] = DFTypeParams(DFType.LINUXCMA, end_cell.get_address(), end_cell.get_address(), 0, 0) # Header is 0
        else:
            for name, value in DFType.iterate():
                match value:
                    case DFType.POOL:
                        self.dftype_params[value] = DFTypeParams(DFType.POOL, 'I60', 'K71', 1, 2) # From I60 to K71, header is 1, filter column is 2
                    case DFType.POLICY:
                        self.dftype_params[value] = DFTypeParams(DFType.POLICY, 'B60', 'F92', 1, 3) # From B60 to F92, header is 1, filter column is 3
                    case DFType.GENPOOL:
                        self.dftype_params[value] = DFTypeParams(DFType.GENPOOL, 'K79', 'L84', 1, 1) # From K79 to L84, header is 1, filter column is 1
                    case DFType.LINUXCMA:
                        self.dftype_params[value] = DFTypeParams(DFType.LINUXCMA, 'L86', 'L86', 0, 0) # From L86 to L86, header is 0, filter column is 0

    def update_cell_with_validation(self, cell_address, new_value):
        """Update a cell value and reapply its data validation"""

        # Preserve the data validation for the cell
        try:
            dv = self.sheet.range(cell_address).api.Validation
            has_validation = dv.Type != -4142  # -4142 indicates no validation
        except Exception as e:
            has_validation = False
        
        if has_validation:
            dv_type = dv.Type
            dv_alert_style = dv.AlertStyle
            dv_operator = dv.Operator
            dv_formula1 = dv.Formula1
            dv_formula2 = dv.Formula2
            try:
                dv.Delete()
            except Exception as e:
                print(f"update_cell_with_validation: fail to delete data validation: {e}. Cell: {cell_address}, value: {new_value}")

        # Update the cell value
        self.sheet[cell_address].value = new_value

        if has_validation:
            # Reapply the data validation
            try:
                new_dv = self.sheet.range(cell_address).api.Validation
                new_dv.Add(
                    dv_type,
                    dv_alert_style,
                    dv_operator,
                    dv_formula1,
                    dv_formula2
                )
            except Exception as e:
                print(f"update_cell_with_validation: failed to reapply validation: {e}. Cell: {cell_address}, value: {new_value}")
    
    def extract_filter_data(self, start_cell, end_cell, header=1, filter_column_index=0):
        """Extract data from a specified range and filter out rows where column E values are None."""
        
        # Force Excel to calculate the formulas before reading the data
        self.sheet.api.Calculate()

        # Read the specified range into a DataFrame
        df = self.sheet.range(f'{start_cell}:{end_cell}').options(
            pd.DataFrame,
            header=header,
            index=False,
            dtype=str,
            numbers=int
        ).value

        # Replace 'NA' strings with pd.NA to enable dropna() to work
        df.replace('NA', pd.NA, inplace=True)

        # Replace 0 in column filter_column_index with pd.NA to enable dropna() to work
        df.replace({df.columns[filter_column_index]: '0'}, pd.NA, inplace=True)
        
        try:
            filtered_df = df.dropna(subset=[df.columns[filter_column_index]])

            # Reset the index as we will iterate over the df and make use of the index value.
            filtered_df = filtered_df.reset_index(drop=True)
        except KeyError:
            print(f"extract_filter_data: failed to drop rows with None values in column {df.columns[filter_column_index]}")
            filtered_df = df

        return filtered_df

    def get_bm_config(self):
        """Get BM configuration"""

        try:
            self.get_revision()
            self.set_model_config_params_cells()
            self.set_model_config_params()
            self.set_dftype_params()
        except Exception as e:
            raise e

        for name, value in ModelConfig.iterate():
            model_config_params = self.model_config_params[value]
            self.update_cell_with_validation(self.model_config_params_cells.cell_lgm_system, model_config_params.cell_lgm_system)
            self.update_cell_with_validation(self.model_config_params_cells.cell_ddr_size, model_config_params.cell_ddr_size)
            self.update_cell_with_validation(self.model_config_params_cells.cell_subsystem, model_config_params.cell_subsystem)
            self.update_cell_with_validation(self.model_config_params_cells.cell_imix_dis_model, model_config_params.cell_imix_dis_model)
            # BM excel sheet does not allow wav614 and wav624 num to be set if wav700 num is non-zero. Set wav700 num to 0 first.
            self.update_cell_with_validation(self.model_config_params_cells.cell_wav700_num, 0)
            self.update_cell_with_validation(self.model_config_params_cells.cell_wav614_num, model_config_params.cell_wav614_num)
            self.update_cell_with_validation(self.model_config_params_cells.cell_wav614_desc, model_config_params.cell_wav614_desc)
            self.update_cell_with_validation(self.model_config_params_cells.cell_wav624_num, model_config_params.cell_wav624_num)
            self.update_cell_with_validation(self.model_config_params_cells.cell_wav624_desc, model_config_params.cell_wav624_desc)
            self.update_cell_with_validation(self.model_config_params_cells.cell_wav700_num, model_config_params.cell_wav700_num)
            self.update_cell_with_validation(self.model_config_params_cells.cell_wav700_desc, model_config_params.cell_wav700_desc)

            # Extract data for each DFType dynamically
            data_frames = {}
            for df_name, df_value in DFType.iterate():
                data_frames[df_name.lower() + '_df'] = self.extract_filter_data(
                    self.dftype_params[df_value].cell_start,
                    self.dftype_params[df_value].cell_end,
                    self.dftype_params[df_value].header,
                    self.dftype_params[df_value].filter_col_idx
                )
            
            # Append bm_config
            self.bm_config[value] = ModelBMConfig(**data_frames)

    def dump_config(self, config):
        """Dump BM configuration"""

        bm_config = self.bm_config[config]
        print(f"Model: {get_name(Model, ModelConfig.model(config))}")
        print(f"Config: {get_name(ModelConfig, config)}")
        for df_name, df_value in DFType.iterate():
            print(f"{df_name}:")
            print(getattr(bm_config, df_name.lower() + '_df'))

    def dump_configs(self):
        """Dump BM configuration"""

        for name, value in ModelConfig.iterate():
            self.dump_config(value)
