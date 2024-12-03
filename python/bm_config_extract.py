# Description:
# This script extracts the BM configuration from the Excel file and generates the dtsi files.
# It works with BN config version starting from V7.03 onwards.
#
# Three files will be generated: bm_main_eth.dtsi, bm_main_pon.dtsi, and bm_main_cable.dtsi.
# The generated dtsi file can be found in the same directory as the python file.
#
# The configurations for each dtsi file are defined in class ModelConfig.
# For example, bm_main_eth.dtsi includes extracted BM configurations for below configurations:
#   - ETH_2GB_GW_WAVE6X4
#   - ETH_2GB_GW_WAVE700
#   - ETH_1GB_GW_WAVE6X4
# Note that each dtsi file includes text other than BM configurations. Those texts are printed
# before the first configuration and after last configuration for each model. In ETH case, the
# header text is printed before ETH_2GB_GW_WAVE6X4. The tail text is printed after
# ETH_1GB_GW_WAVE6X4.
# 
# Author: Leipo Yan
# Date: 2024-12-03
# Version: 1.0

import xlwings as xw
import pandas as pd
import tkinter as tk
from tkinter import filedialog
from datetime import datetime


# Define constants about the excel sheet.
CELL_LGM_SYSTEM = 'C5'
CELL_DDR_SIZE = 'C6'
CELL_SUBSYSTEM = 'C7'
CELL_IMIX_DIS_MODEL = 'C8'
CELL_WAV614_NUM = 'C18'
CELL_WAV614_DESC = 'C19'
CELL_WAV624_NUM = 'C20'
CELL_WAV624_DESC = 'C21'
CELL_WAV700_NUM = 'C24'
CELL_WAV700_DESC = 'C25'

CELL_POLICY_START = 'B60'
CELL_POLICY_END = 'F92'
CELL_POLICY_FILTER_COLUMN = 3

CELL_POOL_START = 'I60'
CELL_POOL_END = 'K71'
CELL_POOL_FILTER_COLUMN = 2

CELL_GENPOOL_START = 'K79'
CELL_GENPOOL_END = 'L84'
CELL_GENPOOL_FILTER_COLUMN = 1

CELL_LINUXCMA = 'L86'

CELL_REVISION = 'C1'

CONST_REVISION_HISTORY_SHEET = 'Revision Hist'
CONST_BM_ALLOCATION_SHEET = 'BM Allocation'
CONST_SYSTEM_ETH = 'Telco_EthWAN_DSL'
CONST_SYSTEM_PON = 'Telco_PON_DSL'
CONST_SYSTEM_CABLE = 'Cable_DocSIS'

CONST_COL_NAME_POOL_ID_CELL = CELL_POOL_START
CONST_COL_NAME_POOL_NUM_CELL = 'K60'
CONST_COL_NAME_POLICY_RESOURCE_TAG_CELL = CELL_POLICY_START
CONST_COL_NAME_POLICY_ID_CELL = 'C60'
CONST_COL_NAME_POLICY_NUM_MIN_CELL = 'E60'
CONST_COL_NAME_POLICY_NUM_MAX_CELL = 'F60'
CONST_COL_NAME_GENPOOL_ID_CELL = CELL_GENPOOL_START
CONST_COL_NAME_GENPOOL_SIZE_CELL = 'L79'

# Define enumerations for supported configurations
class ModelConfig:
    ETH_2GB_GW_WAVE6X4 = 1
    ETH_2GB_GW_WAVE700 = 2
    ETH_1GB_GW_WAVE6X4 = 3
    PON_2GB_GW_WAVE6X4 = 4
    PON_2GB_GW_WAVE700 = 5
    PON_1GB_GW_WAVE6X4 = 6
    CABLE_2GB_GW_WAVE700 = 7
    CABLE_1GB_MODEM = 8

def is_first_model_config(config):
	return (config == ModelConfig.ETH_2GB_GW_WAVE6X4 or config == ModelConfig.PON_2GB_GW_WAVE6X4 or config == ModelConfig.CABLE_2GB_GW_WAVE700)

def is_last_model_config(config):
	return (config == ModelConfig.ETH_1GB_GW_WAVE6X4 or config == ModelConfig.PON_1GB_GW_WAVE6X4 or config == ModelConfig.CABLE_1GB_MODEM)

def is_eth_model_config(config):
	return (config == ModelConfig.ETH_2GB_GW_WAVE6X4 or config == ModelConfig.ETH_2GB_GW_WAVE700 or config == ModelConfig.ETH_1GB_GW_WAVE6X4)

def is_pon_model_config(config):
	return (config == ModelConfig.PON_2GB_GW_WAVE6X4 or config == ModelConfig.PON_2GB_GW_WAVE700 or config == ModelConfig.PON_1GB_GW_WAVE6X4)

def is_cable_model_config(config):
	return (config == ModelConfig.CABLE_2GB_GW_WAVE700 or config == ModelConfig.CABLE_1GB_MODEM)

def get_output_file_name(config):
    # output_file is bm_main_eth.dtsi for ETH, bm_main_pon.dtsi for PON, bm_main_docsis.dtsi for Cable
    if is_eth_model_config(config):
        return 'bm_main_eth.dtsi'
    elif is_pon_model_config(config):
        return 'bm_main_pon.dtsi'
    elif is_cable_model_config(config):
        return 'bm_main_docsis.dtsi'
    else:
        print("Invalid configuration.")
        return None
    
# Define text for generating dtsi files
g_text_head = """// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2024-{year} MaxLinear, Inc.
 */

#ifndef _BM_MAIN_MODEL_
#define _BM_MAIN_MODEL_

/*
 * ==========================================================================
 * BM pool/policy configuration V{bm_config_version}
 * ==========================================================================
 */

/* DDR configuration checking */
#if defined(CONFIG_DDR_1GB) && defined(CONFIG_DDR_2GB)
#error "Please select only one DDR configuration"
#endif

#if !defined(CONFIG_DDR_1GB) && !defined(CONFIG_DDR_2GB)
#define CONFIG_DDR_2GB
#endif

/* WAVE configuration checking */
#if defined(CONFIG_WAVE_6X4) && defined(CONFIG_WAVE_700)
#error "Please select only one WAVE configuration"
#endif

#if !defined(CONFIG_WAVE_700) && !defined(CONFIG_WAVE_6X4)
#define CONFIG_WAVE_6X4
#endif

/* SUBSYSTEM configuration checking */
#if defined(CONFIG_SUBSYSTEM_GW) && defined(CONFIG_SUBSYSTEM_MODEM)
#error "Please select only one subsystem"
#endif

#if !defined(CONFIG_SUBSYSTEM_GW) && !defined(CONFIG_SUBSYSTEM_MODEM)
#define CONFIG_SUBSYSTEM_GW
#endif

/* Define POOL and policy values */
"""

g_text_tail_eth = """
#else
#error "WAVE700 is not supported with 1GB DDR"
#endif /* CONFIG_WAVE_6X4 */

#else
#error "Please include dtsi file for DDR size"
#endif /* CONFIG_DDR_2GB */

#else
#error "Only GW subsystem is defined for ETHWAN_DSL"
#endif /* CONFIG_SUBSYSTEM_GW */

&cqm_lgm {
	cqm,bm_pools {
		#size-cells = <0>;
		#address-cells = <1>;
		pool@0 {
			reg = <0>;
			pool,buff_sz = <256>;
			pool,pool-num_buffs = <POOL0_NUM_BUF>;
			pool,type = <SSB_NIOC_SHARED>;
		};
		pool@1 {
			reg = <1>;
			pool,buff_sz = <512>;
			pool,pool-num_buffs = <POOL1_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@2 {
			reg = <2>;
			pool,buff_sz = <1024>;
			pool,pool-num_buffs = <POOL2_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@3 {
		reg = <3>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL3_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@4 {
			reg = <4>;
			pool,buff_sz = <10240>;
			pool,pool-num_buffs = <POOL4_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		/* Voice Pool: type = CQM_NIOC_ISOLATED */
		pool@5 {
			reg = <5>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL5_NUM_BUF>;
			pool,type = <CQM_NIOC_ISOLATED>;
		};
		/* CPU Pools: type = CQM_CPU_ISOLATED */
		pool@6 {
			reg = <6>;
			pool,buff_sz = <512>;
			pool,pool-num_buffs = <POOL6_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@7 {
			reg = <7>;
			pool,buff_sz = <1024>;
			pool,pool-num_buffs = <POOL7_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@8 {
			reg = <8>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL8_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@9 {
			reg = <9>;
			pool,buff_sz = <65536>;
			pool,pool-num_buffs = <POOL9_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
	};
	cqm,bm_policies{
		#size-cells = <0>;
		#address-cells = <1>;
		bm_policy@0 {
			reg = <0>;/* Policy Id */
			policy,pool = <0 DP_RES_ID_SYS>,
				      <1 DP_RES_ID_SYS>; /* Pool Id, Type */
			/* <Min Guaranteed, Max Allowed> */
			policy,alloc = <POLICY0_NUM_BUF_MIN POLICY0_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@1 {
			reg = <1>;
			policy,pool = <1 DP_RES_ID_SYS>;
			policy,alloc = <POLICY1_NUM_BUF_MIN POLICY1_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@2 {
			reg = <2>;
			policy,pool = <2 DP_RES_ID_SYS>;
			policy,alloc = <POLICY2_NUM_BUF_MIN POLICY2_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@3 {
			reg = <3>;
			policy,pool = <3 DP_RES_ID_SYS>;
			policy,alloc = <POLICY3_NUM_BUF_MIN POLICY3_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@4 {
			reg = <4>;
			policy,pool = <4 DP_RES_ID_SYS>;
			policy,alloc = <POLICY4_NUM_BUF_MIN POLICY4_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		/* TOE TX policy */
		bm_policy@5 {
			reg = <5>;
			policy,pool = <3 DP_RES_ID_SYS>;
			policy,alloc = <POLICY5_NUM_BUF_MIN POLICY5_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};

		#if defined(CONFIG_WAVE_6X4)
		/* Radio 1: WAV 2.4G Policies */
		bm_policy@6 {
			reg = <6>;
			policy,pool = <3 DP_RES_ID_WAV614>;
			policy,alloc = <POLICY6_NUM_BUF_MIN POLICY6_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@7 {
			reg = <7>;
			policy,pool = <3 DP_RES_ID_WAV614>;
			policy,alloc = <POLICY7_NUM_BUF_MIN POLICY7_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		/* Radio 2: WAV 5/6G Policies */
		bm_policy@8 {
			reg = <8>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY8_NUM_BUF_MIN POLICY8_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@9 {
			reg = <9>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY9_NUM_BUF_MIN POLICY9_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		/* Radio 3: WAV 5/6G Policies */
		bm_policy@10 {
			reg = <10>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY10_NUM_BUF_MIN POLICY10_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@11 {
			reg = <11>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY11_NUM_BUF_MIN POLICY11_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		#endif

		/* DSL Policies */
		bm_policy@12 {
			reg = <12>;
			policy,pool = <3 DP_RES_ID_VRX>;
			policy,alloc = <POLICY12_NUM_BUF_MIN POLICY12_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@13 {
			reg = <13>;
			policy,pool = <1 DP_RES_ID_VRX>;
			policy,alloc = <POLICY13_NUM_BUF_MIN POLICY13_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		bm_policy@14 {
			reg = <14>;
			policy,pool = <2 DP_RES_ID_VRX>;
			policy,alloc = <POLICY14_NUM_BUF_MIN POLICY14_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		bm_policy@15 {
			reg = <15>;
			policy,pool = <3 DP_RES_ID_VRX>;
			policy,alloc = <POLICY15_NUM_BUF_MIN POLICY15_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		bm_policy@16 {
			reg = <16>;
			policy,pool = <4 DP_RES_ID_VRX>;
			policy,alloc = <POLICY16_NUM_BUF_MIN POLICY16_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		/* Voice Policy */
		bm_policy@17 {
			reg = <17>;
			policy,pool = <5 DP_RES_ID_VOICE0>;
			policy,alloc = <POLICY17_NUM_BUF_MIN POLICY17_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		/* CPU Policies */
		bm_policy@18 {
			reg = <18>;
			policy,pool = <6 DP_RES_ID_CPU> ;
			policy,alloc = <POLICY18_NUM_BUF_MIN POLICY18_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@19 {
			reg = <19>;
			policy,pool = <7 DP_RES_ID_CPU>;
			policy,alloc = <POLICY19_NUM_BUF_MIN POLICY19_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@20 {
			reg = <20>;
			policy,pool = <8 DP_RES_ID_CPU>;
			policy,alloc = <POLICY20_NUM_BUF_MIN POLICY20_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@21 {
			reg = <21>;
			policy,pool = <9 DP_RES_ID_CPU>;
			policy,alloc = <POLICY21_NUM_BUF_MIN POLICY21_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};

		#if defined(CONFIG_WAVE_700)
		bm_policy@22 {
			reg = <22>;
			policy,pool = <3 DP_RES_ID_WAV700>;
			policy,alloc = <POLICY22_NUM_BUF_MIN POLICY22_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@23 {
			reg = <23>;
			policy,pool = <3 DP_RES_ID_WAV700>;
			policy,alloc = <POLICY23_NUM_BUF_MIN POLICY23_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		#endif
	};
};

&soc {
	noc_pool: noc_pool {
		compatible = "mxl,lgm-gen-pool";

		icc_pool: icc_pool {
			size = <ICC_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		rw_pool: rw_pool {
			size = <RW_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		cpu_pool: cpu_pool {
			size = <CPU_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		sys_pool: sys_pool {
			size = <SYS_POOL_SIZE>;
			perm = <NOC_RD_PERM>;
		};

		ro_pool: ro_pool {
			size = <RO_POOL_SIZE>;
			perm = <NOC_RD_PERM>;
		};
	};
};

#if (ICC_POOL_SIZE + RW_POOL_SIZE + CPU_POOL_SIZE + SYS_POOL_SIZE + RO_POOL_SIZE) > LINUX_CMA_SIZE
#error "Total size of pools is greater than Linux CMA size"
#endif

&reserved_mem {
	linux,cma {
		compatible = "shared-dma-pool";
		reusable;
		alignment = <0x200000>;
		size = <LINUX_CMA_SIZE>;
		linux,cma-default;
	};
};

&lpid_config {
	mxl,wan-mode = <LPID_WAN_ETH>;
};

#else
#error "Only one bm_main model dtsi can be included"
#endif /* _BM_MAIN_MODEL_ */
"""

g_text_tail_pon = """
#else
#error "WAVE700 is not supported with 1GB DDR"
#endif /* CONFIG_WAVE_6X4 */

#else
#error "Please include dtsi file for DDR size"
#endif /* CONFIG_DDR_2GB */

#else
#error "Only GW subsystem is defined for PON_WAN_DSL"
#endif /* CONFIG_SUBSYSTEM_GW */

&cqm_lgm {
	cqm,bm_pools {
		#size-cells = <0>;
		#address-cells = <1>;
		pool@0 {
			reg = <0>;
			pool,buff_sz = <256>;
			pool,pool-num_buffs = <POOL0_NUM_BUF>;
			pool,type = <SSB_NIOC_SHARED>;
		};
		pool@1 {
			reg = <1>;
			pool,buff_sz = <512>;
			pool,pool-num_buffs = <POOL1_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@2 {
			reg = <2>;
			pool,buff_sz = <1024>;
			pool,pool-num_buffs = <POOL2_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@3 {
		reg = <3>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL3_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@4 {
			reg = <4>;
			pool,buff_sz = <10240>;
			pool,pool-num_buffs = <POOL4_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		/* Voice Pool: type = CQM_NIOC_ISOLATED */
		pool@5 {
			reg = <5>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL5_NUM_BUF>;
			pool,type = <CQM_NIOC_ISOLATED>;
		};
		/* CPU Pools: type = CQM_CPU_ISOLATED */
		pool@6 {
			reg = <6>;
			pool,buff_sz = <512>;
			pool,pool-num_buffs = <POOL6_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@7 {
			reg = <7>;
			pool,buff_sz = <1024>;
			pool,pool-num_buffs = <POOL7_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@8 {
			reg = <8>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL8_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@9 {
			reg = <9>;
			pool,buff_sz = <65536>;
			pool,pool-num_buffs = <POOL9_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
	};
	cqm,bm_policies{
		#size-cells = <0>;
		#address-cells = <1>;
		bm_policy@0 {
			reg = <0>;/* Policy Id */
			policy,pool = <0 DP_RES_ID_SYS>,
				      <1 DP_RES_ID_SYS>; /* Pool Id, Type */
			/* <Min Guaranteed, Max Allowed> */
			policy,alloc = <POLICY0_NUM_BUF_MIN POLICY0_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@1 {
			reg = <1>;
			policy,pool = <1 DP_RES_ID_SYS>;
			policy,alloc = <POLICY1_NUM_BUF_MIN POLICY1_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@2 {
			reg = <2>;
			policy,pool = <2 DP_RES_ID_SYS>;
			policy,alloc = <POLICY2_NUM_BUF_MIN POLICY2_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@3 {
			reg = <3>;
			policy,pool = <3 DP_RES_ID_SYS>;
			policy,alloc = <POLICY3_NUM_BUF_MIN POLICY3_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@4 {
			reg = <4>;
			policy,pool = <4 DP_RES_ID_SYS>;
			policy,alloc = <POLICY4_NUM_BUF_MIN POLICY4_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		/* TOE TX policy */
		bm_policy@5 {
			reg = <5>;
			policy,pool = <3 DP_RES_ID_SYS>;
			policy,alloc = <POLICY5_NUM_BUF_MIN POLICY5_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};

		#if defined(CONFIG_WAVE_6X4)
		/* Radio 1: WAV 2.4G Policies */
		bm_policy@6 {
			reg = <6>;
			policy,pool = <3 DP_RES_ID_WAV614>;
			policy,alloc = <POLICY6_NUM_BUF_MIN POLICY6_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@7 {
			reg = <7>;
			policy,pool = <3 DP_RES_ID_WAV614>;
			policy,alloc = <POLICY7_NUM_BUF_MIN POLICY7_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		/* Radio 2: WAV 5/6G Policies */
		bm_policy@8 {
			reg = <8>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY8_NUM_BUF_MIN POLICY8_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@9 {
			reg = <9>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY9_NUM_BUF_MIN POLICY9_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		/* Radio 3: WAV 5/6G Policies */
		bm_policy@10 {
			reg = <10>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY10_NUM_BUF_MIN POLICY10_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@11 {
			reg = <11>;
			policy,pool = <3 DP_RES_ID_WAV624>;
			policy,alloc = <POLICY11_NUM_BUF_MIN POLICY11_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		#endif

		/* DSL Policies */
		bm_policy@12 {
			reg = <12>;
			policy,pool = <3 DP_RES_ID_VRX>;
			policy,alloc = <POLICY12_NUM_BUF_MIN POLICY12_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@13 {
			reg = <13>;
			policy,pool = <1 DP_RES_ID_VRX>;
			policy,alloc = <POLICY13_NUM_BUF_MIN POLICY13_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		bm_policy@14 {
			reg = <14>;
			policy,pool = <2 DP_RES_ID_VRX>;
			policy,alloc = <POLICY14_NUM_BUF_MIN POLICY14_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		bm_policy@15 {
			reg = <15>;
			policy,pool = <3 DP_RES_ID_VRX>;
			policy,alloc = <POLICY15_NUM_BUF_MIN POLICY15_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		bm_policy@16 {
			reg = <16>;
			policy,pool = <4 DP_RES_ID_VRX>;
			policy,alloc = <POLICY16_NUM_BUF_MIN POLICY16_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		/* Voice Policy */
		bm_policy@17 {
			reg = <17>;
			policy,pool = <5 DP_RES_ID_VOICE0>;
			policy,alloc = <POLICY17_NUM_BUF_MIN POLICY17_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		/* CPU Policies */
		bm_policy@18 {
			reg = <18>;
			policy,pool = <6 DP_RES_ID_CPU> ;
			policy,alloc = <POLICY18_NUM_BUF_MIN POLICY18_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@19 {
			reg = <19>;
			policy,pool = <7 DP_RES_ID_CPU>;
			policy,alloc = <POLICY19_NUM_BUF_MIN POLICY19_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@20 {
			reg = <20>;
			policy,pool = <8 DP_RES_ID_CPU>;
			policy,alloc = <POLICY20_NUM_BUF_MIN POLICY20_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@21 {
			reg = <21>;
			policy,pool = <9 DP_RES_ID_CPU>;
			policy,alloc = <POLICY21_NUM_BUF_MIN POLICY21_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};

		#if defined(CONFIG_WAVE_700)
		bm_policy@22 {
			reg = <22>;
			policy,pool = <3 DP_RES_ID_WAV700>;
			policy,alloc = <POLICY22_NUM_BUF_MIN POLICY22_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@23 {
			reg = <23>;
			policy,pool = <3 DP_RES_ID_WAV700>;
			policy,alloc = <POLICY23_NUM_BUF_MIN POLICY23_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		#endif
	};
};

&soc {
	noc_pool: noc_pool {
		compatible = "mxl,lgm-gen-pool";

		icc_pool: icc_pool {
			size = <ICC_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		rw_pool: rw_pool {
			size = <RW_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		cpu_pool: cpu_pool {
			size = <CPU_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		sys_pool: sys_pool {
			size = <SYS_POOL_SIZE>;
			perm = <NOC_RD_PERM>;
		};

		ro_pool: ro_pool {
			size = <RO_POOL_SIZE>;
			perm = <NOC_RD_PERM>;
		};
	};
};

#if (ICC_POOL_SIZE + RW_POOL_SIZE + CPU_POOL_SIZE + SYS_POOL_SIZE + RO_POOL_SIZE) > LINUX_CMA_SIZE
#error "Total size of pools is greater than Linux CMA size"
#endif

&reserved_mem {
	linux,cma {
		compatible = "shared-dma-pool";
		reusable;
		alignment = <0x200000>;
		size = <LINUX_CMA_SIZE>;
		linux,cma-default;
	};
};

&lpid_config {
	mxl,wan-mode = <LPID_WAN_PON>;
};

#else
#error "Only one bm_main model dtsi can be included"
#endif /* _BM_MAIN_MODEL_ */
"""

g_text_tail_cable = """
#else
#error "Only 1GB DDR is supported with MODEM"
#endif /* CONFIG_DDR_1GB */
#else
#error "Please select a subsystem"
#endif /* CONFIG_SUBSYSTEM_MODEM */

&cqm_lgm {
	cqm,bm_pools {
		#size-cells = <0>;
		#address-cells = <1>;
		pool@0 {
			reg = <0>;
			pool,buff_sz = <256>;
			pool,pool-num_buffs = <POOL0_NUM_BUF>;
			pool,type = <SSB_NIOC_SHARED>;
		};
		pool@1 {
			reg = <1>;
			pool,buff_sz = <512>;
			pool,pool-num_buffs = <POOL1_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@2 {
			reg = <2>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL2_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		pool@3 {
			reg = <3>;
			pool,buff_sz = <10240>;
			pool,pool-num_buffs = <POOL3_NUM_BUF>;
			pool,type = <CQM_NIOC_SHARED>;
		};
		/* Voice Pool: type = CQM_NIOC_ISOLATED */
		pool@4 {
			reg = <4>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL4_NUM_BUF>;
			pool,type = <CQM_NIOC_ISOLATED>;
		};
		/* CPU Pools: type = CQM_CPU_ISOLATED */
		pool@5 {
			reg = <5>;
			pool,buff_sz = <512>;
			pool,pool-num_buffs = <POOL5_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@6 {
			reg = <6>;
			pool,buff_sz = <1024>;
			pool,pool-num_buffs = <POOL6_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@7 {
			reg = <7>;
			pool,buff_sz = <2048>;
			pool,pool-num_buffs = <POOL7_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
		pool@8 {
			reg = <8>;
			pool,buff_sz = <65536>;
			pool,pool-num_buffs = <POOL8_NUM_BUF>;
			pool,type = <CQM_CPU_ISOLATED>;
		};
	};
	cqm,bm_policies {
		#size-cells = <0>;
		#address-cells = <1>;
		bm_policy@0 {
			reg = <0>;/* Policy Id */
			policy,pool = <0 DP_RES_ID_SYS>,
				      <1 DP_RES_ID_SYS>; /* Pool Id, Type */
			/* <Min Guaranteed, Max Allowed> */
			policy,alloc = <POLICY0_NUM_BUF_MIN POLICY0_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@1 {
			reg = <1>;
			policy,pool = <1 DP_RES_ID_SYS>;
			policy,alloc = <POLICY1_NUM_BUF_MIN POLICY1_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@2 {
			reg = <2>;
			policy,pool = <2 DP_RES_ID_SYS>;
			policy,alloc = <POLICY2_NUM_BUF_MIN POLICY2_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@3 {
			reg = <3>;
			policy,pool = <3 DP_RES_ID_SYS>;
			policy,alloc = <POLICY3_NUM_BUF_MIN POLICY3_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		/* TOE TX policy */
		bm_policy@4 {
			reg = <4>;
			policy,pool = <2 DP_RES_ID_SYS>;
			policy,alloc = <POLICY4_NUM_BUF_MIN POLICY4_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		/* Voice Policy */
		bm_policy@16 {
			reg = <16>;
			policy,pool = <4 DP_RES_ID_VOICE0>;
			policy,alloc = <POLICY16_NUM_BUF_MIN POLICY16_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		/* CPU Policies */
		bm_policy@17 {
			reg = <17>;
			policy,pool = <5 DP_RES_ID_CPU> ;
			policy,alloc = <POLICY17_NUM_BUF_MIN POLICY17_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@18 {
			reg = <18>;
			policy,pool = <6 DP_RES_ID_CPU> ;
			policy,alloc = <POLICY18_NUM_BUF_MIN POLICY18_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@19 {
			reg = <19>;
			policy,pool = <7 DP_RES_ID_CPU> ;
			policy,alloc = <POLICY19_NUM_BUF_MIN POLICY19_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@20 {
			reg = <20>;
			policy,pool = <8 DP_RES_ID_CPU> ;
			policy,alloc = <POLICY20_NUM_BUF_MIN POLICY20_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};

		#if defined(CONFIG_WAVE_700)
		bm_policy@21 {
			reg = <21>;
			policy,pool = <2 DP_RES_ID_WAV700>;
			policy,alloc = <POLICY21_NUM_BUF_MIN POLICY21_NUM_BUF_MAX>;
			policy,direction = <CQM_RX>;
		};
		bm_policy@22 {
			reg = <22>;
			policy,pool = <2 DP_RES_ID_WAV700>;
			policy,alloc = <POLICY22_NUM_BUF_MIN POLICY22_NUM_BUF_MAX>;
			policy,direction = <CQM_TX>;
		};
		#endif

		bm_policy@23 {
			reg = <23>;
			policy,pool = <1 DP_RES_ID_DOCSIS>;
			policy,alloc = <POLICY23_NUM_BUF_MIN POLICY23_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@24 {
			reg = <24>;
			policy,pool = <2 DP_RES_ID_DOCSIS>;
			policy,alloc = <POLICY24_NUM_BUF_MIN POLICY24_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@25 {
			reg = <25>;
			policy,pool = <3 DP_RES_ID_DOCSIS>;
			policy,alloc = <POLICY25_NUM_BUF_MIN POLICY25_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@26 {
			reg = <26>;
			policy,pool = <2 DP_RES_ID_DOCSIS_MMM>;
			policy,alloc = <POLICY26_NUM_BUF_MIN POLICY26_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
		bm_policy@27 {
			reg = <27>;
			policy,pool = <2 DP_RES_ID_DOCSIS_VOICE>;
			policy,alloc = <POLICY27_NUM_BUF_MIN POLICY27_NUM_BUF_MAX>;
			policy,direction = <CQM_TX_RX>;
		};
	};
};

&soc {
	noc_pool: noc_pool {
		compatible = "mxl,lgm-gen-pool";

		icc_pool: icc_pool {
			size = <ICC_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		rw_pool: rw_pool {
			size = <RW_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		cpu_pool: cpu_pool {
			size = <CPU_POOL_SIZE>;
			perm = <NOC_RW_PERM>;
		};

		sys_pool: sys_pool {
			size = <SYS_POOL_SIZE>;
			perm = <NOC_RD_PERM>;
		};

		ro_pool: ro_pool {
			size = <RO_POOL_SIZE>;
			perm = <NOC_RD_PERM>;
		};
	};
};

#if (ICC_POOL_SIZE + RW_POOL_SIZE + CPU_POOL_SIZE + SYS_POOL_SIZE + RO_POOL_SIZE) > LINUX_CMA_SIZE
#error "Total size of pools is greater than Linux CMA size"
#endif

&reserved_mem {
	linux,cma {
		compatible = "shared-dma-pool";
		reusable;
		alignment = <0x200000>;
		size = <LINUX_CMA_SIZE>;
		linux,cma-default;
	};
};

&lpid_config {
	mxl,wan-mode = <LPID_WAN_DOCSIS>;
};

#else
#error "Only one bm_main model dtsi can be included"
#endif /* _BM_MAIN_MODEL_ */
"""
    
# Define a dictionary to map ModelConfig to a string
model_config_str = {
    ModelConfig.ETH_2GB_GW_WAVE6X4: """
#ifdef CONFIG_SUBSYSTEM_GW
#ifdef CONFIG_DDR_2GB
#ifdef CONFIG_WAVE_6X4
/*****************************************************
 * EthWAN_DSL + GW + 2GB DDR + WAVE6xx
 *****************************************************/
 """,
    ModelConfig.ETH_2GB_GW_WAVE700: """
#elif defined(CONFIG_WAVE_700)
/*****************************************************
 * EthWAN_DSL + GW + 2GB DDR + WAVE700
 *****************************************************/
""",
    ModelConfig.ETH_1GB_GW_WAVE6X4: """
#else
#error "Please include dtsi file for WAVE configuration"
#endif /* CONFIG_WAVE_6X4 */

#elif defined(CONFIG_DDR_1GB)
#ifdef CONFIG_WAVE_6X4
/****************************************************
 * EthWAN_DSL + GW + 1GB DDR + WAVE6xx
 ****************************************************/
""",
    ModelConfig.PON_2GB_GW_WAVE6X4: """
#ifdef CONFIG_SUBSYSTEM_GW
#ifdef CONFIG_DDR_2GB
#ifdef CONFIG_WAVE_6X4
/****************************************************
 * PON_WAN_DSL + GW + 2GB DDR + WAVE6xx
 ****************************************************/
""",
    ModelConfig.PON_2GB_GW_WAVE700: """
#elif defined(CONFIG_WAVE_700)
/***************************************************
 * PON_WAN_DSL + GW + 2GB DDR + WAVE700
 ***************************************************/
""",
    ModelConfig.PON_1GB_GW_WAVE6X4: """
#else
#error "Please include dtsi file for WAVE configuration"
#endif /* CONFIG_WAVE_6X4 */

#elif defined(CONFIG_DDR_1GB)
#ifdef CONFIG_WAVE_6X4
/***************************************************
 * PON_WAN_DSL + GW + 1GB DDR + WAVE6xx
 ***************************************************/
""",
    ModelConfig.CABLE_2GB_GW_WAVE700: """
#ifdef CONFIG_SUBSYSTEM_GW
#ifdef CONFIG_DDR_2GB
#ifdef CONFIG_WAVE_700
/***************************************************
 * Cable GW + GW + 2GB DDR + WAVE700
 ***************************************************/
""",
    ModelConfig.CABLE_1GB_MODEM: """
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
"""
}

# define a global variable to store config version
bm_config_version = None

def get_bm_config_version(sheet):
    """Get the BM Config version."""
    global bm_config_version
    bm_config_version = sheet.range(CELL_REVISION).expand('down').value[-1]

def update_cell_with_validation(sheet, cell_address, new_value):
    """Update a cell value and reapply its data validation."""
    # Preserve the data validation for the cell
    try:
        dv = sheet.range(cell_address).api.Validation
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
            print(f"update_cell_with_validation: fail to delete data validation: {e}")

    # Update the cell value
    sheet[cell_address].value = new_value

    if has_validation:
        # Reapply the data validation
        try:
            new_dv = sheet.range(cell_address).api.Validation
            new_dv.Add(
                dv_type,
                dv_alert_style,
                dv_operator,
                dv_formula1,
                dv_formula2
            )
        except Exception as e:
            print(f"update_cell_with_validation: failed to reapply validation: {e}")

def extract_filter_data(sheet, start_cell, end_cell, filter_column_index):
    """Extract data from a specified range and filter out rows where column E values are None."""
    # Read the specified range into a DataFrame
    df = sheet.range(f'{start_cell}:{end_cell}').options(pd.DataFrame, header=1, index=False, dtype=str, numbers=int).value

    # Replace 'NA' strings with pd.NA to enable dropna() to work
    df.replace('NA', pd.NA, inplace=True)

    # Replace 0 in column filter_column_index with pd.NA to enable dropna() to work
    df.replace({df.columns[filter_column_index]: '0'}, pd.NA, inplace=True)
    
    try:
        filtered_df = df.dropna(subset=[df.columns[filter_column_index]])
    except KeyError:
        print(f"extract_filter_data: failed to drop rows with None values in column {df.columns[filter_column_index]}")
        filtered_df = df

    return filtered_df

def record_data_to_file(sheet, config):
    sheet.api.Calculate()
    policy_df = extract_filter_data(sheet, CELL_POLICY_START, CELL_POLICY_END, CELL_POLICY_FILTER_COLUMN)
    pool_df = extract_filter_data(sheet, CELL_POOL_START, CELL_POOL_END, CELL_POOL_FILTER_COLUMN)
    genpool_df = extract_filter_data(sheet, CELL_GENPOOL_START, CELL_GENPOOL_END, CELL_GENPOOL_FILTER_COLUMN)

    output_file = get_output_file_name(config)
    if output_file is None:
        return

    with open(output_file, 'a' if not is_first_model_config(config) else 'w', newline='\n') as f:
        # If it's first model config, write the header and BM config version
        if is_first_model_config(config):
            f.write(g_text_head.format(year=datetime.now().year, bm_config_version=bm_config_version))

        # Write the model configuration
        f.write(model_config_str[config] + '\n')

        # Write extracted pool, policy and genpool data to the file
        for index, row in pool_df.iterrows():
            f.write(f"#define POOL{row[sheet[CONST_COL_NAME_POOL_ID_CELL].value]}_NUM_BUF {row[sheet[CONST_COL_NAME_POOL_NUM_CELL].value]}\n")
        
        f.write(f"\n")
        for index, row in policy_df.iterrows():
            if row[sheet[CONST_COL_NAME_POLICY_RESOURCE_TAG_CELL].value]:
                f.write(f"/* {row[sheet[CONST_COL_NAME_POLICY_RESOURCE_TAG_CELL].value]} */\n")
            f.write(f"#define POLICY{row[sheet[CONST_COL_NAME_POLICY_ID_CELL].value]}_NUM_BUF_MIN {row[sheet[CONST_COL_NAME_POLICY_NUM_MIN_CELL].value]}\n")
            f.write(f"#define POLICY{row[sheet[CONST_COL_NAME_POLICY_ID_CELL].value]}_NUM_BUF_MAX {row[sheet[CONST_COL_NAME_POLICY_NUM_MAX_CELL].value]}\n")
        
        f.write(f"\n")
        for index, row in genpool_df.iterrows():
            f.write(f"#define {row[sheet[CONST_COL_NAME_GENPOOL_ID_CELL].value].replace(" ", "")}_POOL_SIZE 0x{row[sheet[CONST_COL_NAME_GENPOOL_SIZE_CELL].value]}\n")
        
        f.write(f"\n")
        f.write(f"#define LINUX_CMA_SIZE 0x{sheet[CELL_LINUXCMA].value}\n")

        # If it's last model config, write the tail
        if is_last_model_config(config):
            if is_eth_model_config(config):
                f.write(g_text_tail_eth)
            elif is_pon_model_config(config):
                f.write(g_text_tail_pon)
            elif is_cable_model_config(config):
                f.write(g_text_tail_cable)

def process_model_config(sheet, config):
    match config:
        case ModelConfig.ETH_2GB_GW_WAVE6X4:
            # ETH + DDR 2G + Gateway + WAV6x4
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_ETH)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '2048')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Gateway')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'Telco')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '1')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '10000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '2')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '20000')
            record_data_to_file(sheet, ModelConfig.ETH_2GB_GW_WAVE6X4)

        case ModelConfig.ETH_2GB_GW_WAVE700:
            # ETH + DDR 2G + Gateway + WAVE700
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_ETH)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '2048')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Gateway')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'Telco')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '10000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '20000')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '1')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            record_data_to_file(sheet, ModelConfig.ETH_2GB_GW_WAVE700)

        case ModelConfig.ETH_1GB_GW_WAVE6X4:
            # ETH + DDR 1G + Gateway + WAVE6x4
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_ETH)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '1024')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Gateway')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'Telco')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '1')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '5000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '2')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '10000')
            record_data_to_file(sheet, ModelConfig.ETH_1GB_GW_WAVE6X4)

        case ModelConfig.PON_2GB_GW_WAVE6X4:
            # PON + DDR 2G + Gateway + WAV6x4
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_PON)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '2048')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Gateway')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'Telco')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '1')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '10000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '2')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '20000')
            record_data_to_file(sheet, ModelConfig.PON_2GB_GW_WAVE6X4)

        case ModelConfig.PON_2GB_GW_WAVE700:
            # PON + DDR 2G + Gateway + WAVE700
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_PON)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '2048')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Gateway')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'Telco')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '10000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '20000')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '1')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            record_data_to_file(sheet, ModelConfig.PON_2GB_GW_WAVE700)

        case ModelConfig.PON_1GB_GW_WAVE6X4:
            # PON + DDR 1G + Gateway + WAVE6x4
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_PON)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '1024')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Gateway')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'Telco')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '1')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '5000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '2')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '10000')
            record_data_to_file(sheet, ModelConfig.PON_1GB_GW_WAVE6X4)

        case ModelConfig.CABLE_2GB_GW_WAVE700:
            # Cable + DDR 2G + Gateway + WAVE700
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_CABLE)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '2048')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Gateway')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'AVM Captures')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '10000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '20000')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '1')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            record_data_to_file(sheet, ModelConfig.CABLE_2GB_GW_WAVE700)

        case ModelConfig.CABLE_1GB_MODEM:
            # Cable + DDR 1G + Modem
            update_cell_with_validation(sheet, CELL_LGM_SYSTEM, CONST_SYSTEM_CABLE)
            update_cell_with_validation(sheet, CELL_DDR_SIZE, '1024')
            update_cell_with_validation(sheet, CELL_SUBSYSTEM, 'Modem')
            update_cell_with_validation(sheet, CELL_IMIX_DIS_MODEL, 'AVM Captures')
            update_cell_with_validation(sheet, CELL_WAV700_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV700_DESC, '80000')
            update_cell_with_validation(sheet, CELL_WAV614_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV614_DESC, '10000')
            update_cell_with_validation(sheet, CELL_WAV624_NUM, '0')
            update_cell_with_validation(sheet, CELL_WAV624_DESC, '20000')
            record_data_to_file(sheet, ModelConfig.CABLE_1GB_MODEM)

def main_process():
    # Pop up a file dialog to select the Excel file
    tk.Tk().withdraw()
    file_path = filedialog.askopenfilename(
        filetypes=[('Excel files', '*.xlsx'), ('All files', '*.*')]
    )

    try:
        # Open the Excel workbook
        app = xw.App(visible=False)  # Set to False to run Excel in the background
        wb = app.books.open(file_path)
        get_bm_config_version(wb.sheets[CONST_REVISION_HISTORY_SHEET])

        sheet = wb.sheets[CONST_BM_ALLOCATION_SHEET]

        for name, value in vars(ModelConfig).items():
            if not name.startswith('__'):
            	process_model_config(sheet, value)
        
		# close the workbook
        wb.close()
    except Exception as e:
        print(f"main_process: An error occurred: {e}")
    finally:
        app.quit()

main_process()

