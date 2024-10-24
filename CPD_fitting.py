import sys, os, re, subprocess
import pandas as pd

results = sys.argv[1]

if not os.path.exists(results):
    os.makedirs(results)
    print(f"Created results directory {results}")

subjects = pd.read_csv("/media/labs/rsmith/lab-members/cgoldman/change_point_detection/CPD_subjects.csv")


models = [
    {'field': 'reward_lr,inverse_temp,reward_prior,decision_thresh,starting_bias,drift_baseline,drift_mod', 'drift_mapping': 'action_prob', 'bias_mapping': '', 'thresh_mapping': ''},
    {'field': 'reward_lr,inverse_temp,reward_prior,decision_thresh,starting_bias,drift_baseline,drift_mod', 'drift_mapping': '', 'bias_mapping': 'action_prob', 'thresh_mapping': ''},
    {'field': 'reward_lr,inverse_temp,reward_prior,decision_thresh,starting_bias,drift_baseline,drift_mod', 'drift_mapping': 'action_prob', 'bias_mapping': 'action_prob', 'thresh_mapping': ''},

]



for index, model in enumerate(models, start=1):
    combined_results_dir = os.path.join(results, f"model{index}")
    drift_mapping = model['drift_mapping']
    bias_mapping = model['bias_mapping']
    thresh_mapping = model['thresh_mapping']
    field = model['field']

    simfit_drift_mapping = drift_mapping
    simfit_bias_mapping = bias_mapping
    simfit_thresh_mapping = thresh_mapping
    simfit_field = field

    for subject in subjects:

        if not os.path.exists(f"{combined_results_dir}/logs"):
            os.makedirs(f"{combined_results_dir}/logs")
            print(f"Created results-logs directory {combined_results_dir}/logs")
        
        ssub_path = '/media/labs/rsmith/lab-members/cgoldman/change_point_detection/CPD_scripts_DDM/CPD_RL_DDM_test_multiple_models.ssub'
        stdout_name = f"{combined_results_dir}/logs/CPD-%J-{subject}.stdout"
        stderr_name = f"{combined_results_dir}/logs/CPD-%J-{subject}.stderr"

        jobname = f'CPD-Model-{index}'
        os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} \"{combined_results_dir}\" \"{field}\" \"{drift_mapping}\" \"{bias_mapping}\" \"{thresh_mapping}\" \"{simfit_field}\" \"{simfit_drift_mapping}\" \"{simfit_bias_mapping}\" \"{simfit_thresh_mapping}\"")

        print(f"SUBMITTED JOB [{jobname}]")
    

 
    
# ###python3 run_RL_DDM_test_multiple_models.py /media/labs/rsmith/lab-members/cgoldman/go_no_go/DDM/RL_DDM_Millner/RL_DDM_fits/simfit_winning_model_nonhierarchical 1 1 1
# joblist | grep GNG | grep -Po 13..... | xargs -n1 scancel