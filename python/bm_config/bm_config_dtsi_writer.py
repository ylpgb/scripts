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
import io
import re

class BMConfigDTSIWriter:
    def __init__(self, BMConfig, eth_file="bm_main_eth.dtsi", pon_file="bm_main_pon.dtsi", cable_file="bm_main_docsis.dtsi"):
        self.BMConfig = BMConfig
        self.eth_file = eth_file
        self.pon_file = pon_file
        self.cable_file = cable_file
        self.bm_config_dir = os.path.dirname(os.path.abspath(__file__))
        self.post_config_token = '&cqm_lgm'

        # Define a dictionary to store the output text for each model config
        self.model_config_text = {}
            
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

    def populate_model_config_test(self):
        for name, value in ModelConfig.iterate():
            output = io.StringIO()
            self.write_dtsi_model_pool(output, self.BMConfig.bm_config[value].pool_df)
            self.write_dtsi_model_policy(output, self.BMConfig.bm_config[value].policy_df)
            self.write_dtsi_model_genpool(output, self.BMConfig.bm_config[value].genpool_df)
            self.write_dtsi_model_linux_cma(output, self.BMConfig.bm_config[value].linuxcma_df)
            self.model_config_text[value] = output.getvalue()

    def replace_braces_after_match(self, text, match_text):
        # Find the position of the match_text
        match = re.search(re.escape(match_text), text)
        if not match:
            return text

        # Split the text into two parts: before and after the match
        before_match = text[:match.end()]
        after_match = text[match.end():]

        # Replace { with << and } with >> in the after_match part
        after_match = after_match.replace('{', '<<').replace('}', '>>')

        # Combine the parts back together
        return before_match + after_match

    def revert_replace(self, text):
        return text.replace('<<', '{').replace('>>', '}')

    def format_output(self, template_file, model_configs):
        with open(os.path.join(self.bm_config_dir, template_file), 'r') as template:
            output = template.read()
            output = self.replace_braces_after_match(output, self.post_config_token)
            output = output.format(year=datetime.now().year,
                                   bm_config_version=self.BMConfig.revision,
                                   **{config_name: self.model_config_text[config_value] for config_name, config_value in model_configs.items()})
            output = self.revert_replace(output)
        return output

    def get_model_configurations(self, prefix):
        return {attr: getattr(ModelConfig, attr) for attr in dir(ModelConfig) if attr.startswith(prefix)}
    
    def generate_model_config_text(self, model):
        # model_templates = {
        #     Model.ETH: ('bm_main_eth.dtsi', {
        #         'ETH_2GB_GW_WAVE6X4': ModelConfig.ETH_2GB_GW_WAVE6X4,
        #         'ETH_2GB_GW_WAVE700': ModelConfig.ETH_2GB_GW_WAVE700,
        #         'ETH_1GB_GW_WAVE6X4': ModelConfig.ETH_1GB_GW_WAVE6X4
        #     }),
        #     Model.PON: ('bm_main_pon.dtsi', {
        #         'PON_2GB_GW_WAVE6X4': ModelConfig.PON_2GB_GW_WAVE6X4,
        #         'PON_2GB_GW_WAVE700': ModelConfig.PON_2GB_GW_WAVE700,
        #         'PON_1GB_GW_WAVE6X4': ModelConfig.PON_1GB_GW_WAVE6X4
        #     }),
        #     Model.CABLE: ('bm_main_docsis.dtsi', {
        #         'CABLE_2GB_GW_WAVE700': ModelConfig.CABLE_2GB_GW_WAVE700,
        #         'CABLE_1GB_MODEM': ModelConfig.CABLE_1GB_MODEM
        #     })
        # }
        model_templates = {
            Model.ETH: ('bm_main_eth.dtsi', self.get_model_configurations('ETH')),
            Model.PON: ('bm_main_pon.dtsi', self.get_model_configurations('PON')),
            Model.CABLE: ('bm_main_docsis.dtsi', self.get_model_configurations('CABLE'))
        }

        if model not in model_templates:
            raise ValueError(f"Invalid model: {model}")

        template_file, model_configs = model_templates[model]
        return self.format_output(template_file, model_configs)

    def write_dtsi_model(self, model):
        match model:
            case Model.ETH:
                output_file = self.eth_file
            case Model.PON:
                output_file = self.pon_file
            case Model.CABLE:
                output_file = self.cable_file
            case _:
                raise ValueError(f"Invalid model: {model}")

        with open(output_file, 'w', newline='\n') as f:
            f.write(self.generate_model_config_text(model))

    def write_dtsi(self):
        self.populate_model_config_test()

        for name, value in Model.iterate():
            self.write_dtsi_model(value)
