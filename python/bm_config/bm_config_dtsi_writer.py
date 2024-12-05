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

class BMConfigDTSIWriter:
    # Define text for generating dtsi files
    text_head = textwrap.dedent("""\
        // SPDX-License-Identifier: GPL-2.0
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
    """)

    text_tail_eth = textwrap.dedent("""\
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
    """)

    text_tail_pon = textwrap.dedent("""\
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
    """)

    text_tail_cable = textwrap.dedent("""\
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

        #if defined(CONFIG_DDR_1GB)
        &ppv4 {
        	num-sessions = <32768>; /* 32K */
        	dma_nioc_sz = <0x1368000>; /* 19MB from rw_pool - depend on num-sessions param */
        };
        #endif
        
        #else
        #error "Only one bm_main model dtsi can be included"
        #endif /* _BM_MAIN_MODEL_ */
    """)

    # Define a dictionary to map ModelConfig to a string
    model_config_str = {
        ModelConfig.ETH_2GB_GW_WAVE6X4: textwrap.dedent("""\
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
        ModelConfig.PON_2GB_GW_WAVE6X4: textwrap.dedent("""\
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
        ModelConfig.CABLE_2GB_GW_WAVE700: textwrap.dedent("""\
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
