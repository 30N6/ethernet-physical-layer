/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

#include "tv.h"
#include "tb.h"
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include "tb_utils.h"

static tv_t * tv_s = NULL;


static int tb_compiletf(char*user_data)
{
	#ifdef DEBUG
	vpi_printf("TB compile\n");
	#endif
	tv_s = tv_alloc();
    return 0;
}

// Drive PCS input values
static int tb_calltf(char*user_data)
{

	uint8_t *data;
	ctrl_lite_s ctrl;
	
	vpiHandle sys;
	vpiHandle argv;
	
	sys = vpi_handle(vpiSysTfCall, 0);
	assert(sys);
	argv = vpi_iterate(vpiArgument, sys);
	assert(argv);
	#ifdef DEBUG
   	vpi_printf("TB call\n");
	#endif
	assert(tv_s);
	
	// create a new packet if none exist
	if (!tv_txd_has_data(tv_s))	tv_create_packet(tv_s);
	// get ctrl and data to drive tx pcs
	tv_get_next_txd(tv_s, &ctrl, data ); 
	
	// write signals through vpi interface
	// ctrl
	tb_vpi_put_logic_1b_t(argv, ctrl.ctrl_v);
	tb_vpi_put_logic_1b_t(argv, ctrl.idle_v);
	// start 
	uint8_t s = 0;
	for(int l=START_W-1; l>-1 ;l--)
		s= (s<<1) & ctrl.start_v[l]; 
	tb_vpi_put_logic_uint8_t(argv, ctrl.start_v);
	tb_vpi_put_logic_1b_t(argv, ctrl.term_v);
	tb_vpi_put_logic_uint8_t(argv, ctrl.term_keep);
	tb_vpi_put_logic_1b_t(argv, ctrl.err_v);
	// data
	_tb_vpi_put_logic_char_var_arr(argv, data,TXD_W);
	//vpi_free_handle(argv);
	return 0;
}
void tb_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.sysfunctype  = 0;
      tf_data.tfname    = "$tb";
      tf_data.calltf    = tb_calltf;
      tf_data.compiletf = tb_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}

// de-init routine
static int tb_end_compiletf(char* path)
{
    return 0;
}

static PLI_INT32 tb_end_calltf(char*user_data){
	if ( tv_s != NULL)tv_free(tv_s);	
	return 0;
}

void tb_end_register()
{
	s_vpi_systf_data tf_end_data;
	
	tf_end_data.type      = vpiSysFunc;
	tf_end_data.sysfunctype  = vpiSysFuncInt;
	tf_end_data.tfname    = "$tb_end";
	tf_end_data.calltf    = tb_end_calltf;
	tf_end_data.compiletf = tb_end_compiletf;
	tf_end_data.sizetf    = 0;
	tf_end_data.user_data = 0;
	vpi_register_systf(&tf_end_data);
}


void (*vlog_startup_routines[])() = {
    tb_end_register,
    tb_register,
    0
};


