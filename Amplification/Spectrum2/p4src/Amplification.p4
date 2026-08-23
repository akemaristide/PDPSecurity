/*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include <core.p4>
#include <spectrum_model.p4>
#include <spectrum_externs.p4>
#include <spectrum_headers.p4>
#include <spectrum_parser.p4>


/* first control after the parser */
control control_in_port(inout nv_headers_t headers,
    in nv_standard_metadata_t std_meta,
    inout nv_empty_metadata_t user_meta) {

    // Mirror 
    action DoMirror(nv_logical_port_t label_port, bit is_truncated, bit<16> truncation_size) {
        nv_mirror(label_port, is_truncated, truncation_size);
    }

    action Drop() {
        nv_drop();
    }

    action Forward(nv_logical_port_t out_port) {
        nv_set_port(out_port);
    }

    table table_port_sampling {
        key = {
            headers.tcp.dst_port  : exact;
        }
        actions = {
            NoAction;
            DoMirror;
            Forward;
            Drop;
        }
        default_action = Drop();
        size = 4096;
    }

    apply {
        table_port_sampling.apply();
    }
}

/* control stage just before L3 routing */
control control_in_rif(inout nv_headers_t headers,
                       in nv_standard_metadata_t std_meta,
                       inout nv_empty_metadata_t user_meta)
{
    apply{}
}

/* post tunnel routing interface stage*/
control control_out_decap(inout nv_headers_t headers,
                          in nv_standard_metadata_t std_meta,
                          inout nv_empty_metadata_t user_meta)
{
       apply{}
}

/* last control in the pipeline, just before the packet goes to deparser and egress */
control control_out_port(inout nv_headers_t headers,
                         in nv_standard_metadata_t std_meta,
                        inout nv_empty_metadata_t user_meta)
{
    apply{}
}

/* The main package for the program pipeline */
NvSpectrumTunnelPipeline (
    nv_fixed_parser(),
    control_in_port(),
    control_in_rif(),
    control_out_decap(),
    control_out_port(),
    nv_fixed_deparser()
) main;