"""
Module Name: bm_config_dtsi_writer.py
Author: Leipo Yan

License: This work is licensed under a Creative Commons Attribution-NonCommercial
4.0 International License.
For more information, visit https://creativecommons.org/licenses/by-nc/4.0/
"""

"""
This module writes the extracted DataFrame into dtsi files.
"""

from .bm_config import *
from datetime import datetime
import textwrap
import os

class BMConfigDTSIWriter:
    # Define a dictionary to map ModelConfig to a string
    model_config_str = {
        ModelConfig.ETH_2GB_GW_WAVE6X4: textwrap.dedent("""
            #ifdef CONFIG_SUBSYSTEM_GW
            #ifdef CONFIG_DDR_2GB
            #ifdef CONFIG_WAVE_6X4
            /*****************************************************
             * EthWAN_DSL + GW + 2GB DDR + WAVE6xx
             *****************************************************/
        """),
        ModelConfig.ETH_2GB_GW_WAVE700: textwrap.dedent("""\
            #elif defined(CONFIG_WAVE_700)
            /*****************************************************
             * EthWAN_DSL + GW + 2GB DDR + WAVE700
             *****************************************************/
        """),
        ModelConfig.ETH_1GB_GW_WAVE6X4: textwrap.dedent("""\
            #else
            #error "Please include dtsi file for WAVE configuration"
            #endif /* CONFIG_WAVE_6X4 */
            
            #elif defined(CONFIG_DDR_1GB)
            #ifdef CONFIG_WAVE_6X4
            /****************************************************
             * EthWAN_DSL + GW + 1GB DDR + WAVE6xx
             ****************************************************/
        """),
        ModelConfig.PON_2GB_GW_WAVE6X4: textwrap.dedent("""
            #ifdef CONFIG_SUBSYSTEM_GW
            #ifdef CONFIG_DDR_2GB
            #ifdef CONFIG_WAVE_6X4
            /****************************************************
             * PON_WAN_DSL + GW + 2GB DDR + WAVE6xx
             ****************************************************/
        """),
        ModelConfig.PON_2GB_GW_WAVE700: textwrap.dedent("""\
            #elif defined(CONFIG_WAVE_700)
            /***************************************************
             * PON_WAN_DSL + GW + 2GB DDR + WAVE700
             ***************************************************/
        """),
        ModelConfig.PON_1GB_GW_WAVE6X4: textwrap.dedent("""\
            #else
            #error "Please include dtsi file for WAVE configuration"
            #endif /* CONFIG_WAVE_6X4 */
            
            #elif defined(CONFIG_DDR_1GB)
            #ifdef CONFIG_WAVE_6X4
            /***************************************************
             * PON_WAN_DSL + GW + 1GB DDR + WAVE6xx
             ***************************************************/
        """),
        ModelConfig.CABLE_2GB_GW_WAVE700: textwrap.dedent("""
            #ifdef CONFIG_SUBSYSTEM_GW
            #ifdef CONFIG_DDR_2GB
            #ifdef CONFIG_WAVE_700
            /***************************************************
             * Cable GW + GW + 2GB DDR + WAVE700
             ***************************************************/
        """),
        ModelConfig.CABLE_1GB_MODEM: textwrap.dedent("""\
            #else
            #error "Only WAVE700 is supported with DOCSIS GW"
            #endif /* CONFIG_WAVE_700 */
            
            #else
            #error "Only 2GB DDR is supported with DOCSIS GW"
            #endif /* CONFIG_DDR_2GB */
            
            #elif defined(CONFIG_SUBSYSTEM_MODEM)
            #if defined(CONFIG_DDR_1GB)
            /**************************************************
             * Cable EMTA + MODEM + 1GB DDR
             **************************************************/
        """)
    }
    
    def __init__(self, BMConfig, eth_file="bm_main_eth.dtsi", pon_file="bm_main_pon.dtsi", cable_file="bm_main_docsis.dtsi"):
        self.BMConfig = BMConfig
        self.eth_file = eth_file
        self.pon_file = pon_file
        self.cable_file = cable_file
        
        bm_config_dir = os.path.dirname(os.path.abspath(__file__))
        self.text_head = self.read_file(os.path.join(bm_config_dir, 'text_head.txt'))
        self.text_tail_eth = self.read_file(os.path.join(bm_config_dir, 'text_tail_eth.txt'))
        self.text_tail_pon = self.read_file(os.path.join(bm_config_dir, 'text_tail_pon.txt'))
        self.text_tail_cable = self.read_file(os.path.join(bm_config_dir, 'text_tail_cable.txt'))

    def read_file(self, file_path):
        with open(file_path, 'r') as f:
            return f.read()
            
    def write_dtsi_model_pool(self, f, pool_df):
        """Write the pool data to the file"""

        if pool_df.empty:
            return
        # Label of the columns may change. So use index to get the data
        id_col = 0
        num_col = 2
        for index, row in pool_df.iterrows():
            f.write(f"#define POOL{pool_df.iloc[index, id_col]}_NUM_BUF {pool_df.iloc[index, num_col]}\n")

    def write_dtsi_model_policy(self, f, policy_df):
        """Write the policy data to the file"""

        if policy_df.empty:
            return
        # Label of the columns may change. So use index to get the data
        tag_col = 0
        id_col = 1
        min_col = 3
        max_col = 4
        f.write(f"\n")
        for index, row in policy_df.iterrows():
            if policy_df.iloc[index, tag_col]:
                f.write(f"/* {policy_df.iloc[index, tag_col]:} */\n")
            f.write(f"#define POLICY{policy_df.iloc[index, id_col]}_NUM_BUF_MIN {policy_df.iloc[index, min_col]:}\n")
            f.write(f"#define POLICY{policy_df.iloc[index, id_col]:}_NUM_BUF_MAX {policy_df.iloc[index, max_col]:}\n")
        
    def write_dtsi_model_genpool(self, f, genpool_df):
        """Write the genpool data to the file"""

        if genpool_df.empty:
            return
        type_col = 0
        size_col = 1
        f.write(f"\n")
        for index, row in genpool_df.iterrows():
            f.write(f"#define {genpool_df.iloc[index, type_col].replace(" ", "")}_POOL_SIZE 0x{genpool_df.iloc[index, size_col]}\n")
            
    def write_dtsi_model_linux_cma(self, f, linux_cma):
        """Write the linux CMA data to the file"""

        if linux_cma.empty:
            return
        f.write(f"\n")
        f.write(f"#define LINUX_CMA_SIZE 0x{linux_cma.iloc[0, 0]}\n")
        f.write(f"\n")
        
    def write_dtsi_model(self, model):
        # Based on model, get output_file
        match model:
            case Model.ETH:
                output_file = self.eth_file
                text_tail = self.text_tail_eth
            case Model.PON:
                output_file = self.pon_file
                text_tail = self.text_tail_pon
            case Model.CABLE:
                output_file = self.cable_file
                text_tail = self.text_tail_cable
            case _:
                raise ValueError(f"Invalid model: {model}")
        
        with open(output_file, 'w', newline='\n') as f:
            f.write(self.text_head.format(year=datetime.now().year, bm_config_version=self.BMConfig.revision))

            for name, value in ModelConfig.iterate():
                if ModelConfig.model(value) == model:
                    f.write(self.model_config_str[value] + '\n')
                    self.write_dtsi_model_pool(f, self.BMConfig.bm_config[value].pool_df)
                    self.write_dtsi_model_policy(f, self.BMConfig.bm_config[value].policy_df)
                    self.write_dtsi_model_genpool(f, self.BMConfig.bm_config[value].genpool_df)
                    self.write_dtsi_model_linux_cma(f, self.BMConfig.bm_config[value].linuxcma_df)

            f.write(text_tail)                  

    def write_dtsi(self):
        for name, value in Model.iterate():
            self.write_dtsi_model(value)
