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

#include <stdio.h>
#include <string.h>
#include <sx/sdk/sx_api.h>
#include <sx/sdk/sx_api_acl.h>
#include <sx/sdk/sx_api_init.h>
#include <sx/sdk/sx_api_span.h>
#include <sx_p4_Amplification.h>


int main(int argc, char **argv) {
    sx_status_t rc;
    sx_api_handle_t handle;
    bool mirror_entry_created = false;
    bool forward_entry_created = false;
    rc = sx_api_open(NULL, &handle);
    if (rc)
    {
        printf("[ERROR] Unable to get sx api handle. rc = %d\n", rc);
        return rc;
    }

    sx_p4_Amplification_init_params_t init_params = {0};
    init_params.disable_devtools_events = true;
    rc = sx_p4_Amplification_init(handle, &init_params);
    if (rc)
    {
        printf("[ERROR] Unable to initialize sampling pipeline functionality. rc = %d\n", rc);
        return rc;
    }

    rc = sx_api_acl_log_verbosity_level_set(handle, SX_LOG_VERBOSITY_BOTH, SX_VERBOSITY_LEVEL_DEBUG, SX_VERBOSITY_LEVEL_DEBUG);
    if (rc)
    {
        printf("[ERROR] Unable to set Verbosity level rc = %d\n", rc);
        goto err;
    }

    uint32_t do_mirror_label_port  = NV_PORT_ID(19); // mirrored packets back to nserver10
    uint32_t forward_out_port      = NV_PORT_ID(19); // forward egress

    sx_p4_Amplification_deinit_params_t deinit_params = {0};
 
    // Sampling/mirror table entries
    sx_p4_control_in_port_table_port_sampling_entry_key_data_t sampling_key_arr[2];
    memset(&sampling_key_arr, 0, sizeof(sampling_key_arr));
    sampling_key_arr[0].headers_tcp_dst_port_value = 0x5000;
    sampling_key_arr[1].headers_tcp_dst_port_value = 0x2000;
    sx_p4_control_in_port_table_port_sampling_entry_action_data_t sampling_data_arr[2];
    memset(&sampling_data_arr, 0, sizeof(sampling_data_arr));
    sampling_data_arr[0].action = SX_P4_CONTROL_IN_PORT_TABLE_PORT_SAMPLING_DOMIRROR_ACTION;
    sampling_data_arr[0].data.DoMirror_params.label_port = do_mirror_label_port;
    sampling_data_arr[0].data.DoMirror_params.is_truncated = FALSE;
    sampling_data_arr[0].data.DoMirror_params.truncation_size = 0x00;
    // Second entry action: Forward to NV_PORT_ID(9)
    sampling_data_arr[1].action = SX_P4_CONTROL_IN_PORT_TABLE_PORT_SAMPLING_FORWARD_ACTION;
    sampling_data_arr[1].data.Forward_params.out_port = forward_out_port;

    // program mirror entry
    rc = sx_p4_control_in_port_table_port_sampling_entry_set(handle, SX_ACCESS_CMD_ADD, &sampling_key_arr[0], &sampling_data_arr[0], 0, NULL);
    if (rc != SX_STATUS_SUCCESS)
    {
        printf("[ERROR] Unable to add acl for table port_sampling. rc= %d\n", rc);
	goto err;
    }
    mirror_entry_created = true;
    printf("[DEBUG] Created Mirror entry\n");

    // Add forward entry for TCP dport 0x2000
    rc = sx_p4_control_in_port_table_port_sampling_entry_set(handle, SX_ACCESS_CMD_ADD, &sampling_key_arr[1], &sampling_data_arr[1], 0, NULL);
    if (rc != SX_STATUS_SUCCESS)
    {
        printf("[ERROR] Unable to add forward entry for table port_sampling. rc= %d\n", rc);
        goto err;
    }
    forward_entry_created = true;
    printf("[DEBUG] Created Forward entry (dport 0x2000 -> NV_PORT_ID(19))\n");

    /* Cleanup */
    char c;

    do {
        printf("to close the app and cleanup: press c\n");
    // no interactive changes; press 'c' to exit
    } while (scanf(" %c", &c) && c != 'c');

    if (mirror_entry_created) {
        rc = sx_p4_control_in_port_table_port_sampling_entry_set(handle, SX_ACCESS_CMD_DELETE, &sampling_key_arr[0], &sampling_data_arr[0], 0, NULL);
        if (rc != SX_STATUS_SUCCESS)
        {
            printf("[ERROR] Unable to remove acl for table port_sampling. rc= %d\n", rc);
            return rc;
        }
        printf("[DEBUG] Deleted Mirror entry\n");
    }


    if (forward_entry_created) {
        rc = sx_p4_control_in_port_table_port_sampling_entry_set(handle, SX_ACCESS_CMD_DELETE, &sampling_key_arr[1], &sampling_data_arr[1], 0, NULL);
        if (rc != SX_STATUS_SUCCESS)
        {
            printf("[ERROR] Unable to remove forward entry for table port_sampling. rc= %d\n", rc);
            return rc;
        }
        printf("[DEBUG] Deleted Forward entry\n");
    }

err:

    rc = sx_p4_Amplification_deinit(handle, &deinit_params);
    if (rc != SX_STATUS_SUCCESS)
    {
        printf("[ERROR] sx_p4_Amplification_deinit failed. rc= %d\n", rc);
        return rc;
    }
    return rc;
}
