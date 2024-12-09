import sys, os, re, subprocess
from datetime import datetime

result_stem = sys.argv[1]

current_datetime = datetime.now().strftime("%m-%d-%Y_%H-%M-%S")
result_stem = f"{result_stem}_{current_datetime}/"

if not os.path.exists(result_stem):
    os.makedirs(result_stem)
    print(f"Created results directory {result_stem}")


subject_list_path = "/media/labs/rsmith/lab-members/cgoldman/change_point_detection/T500_list.csv"
subjects = []
with open(subject_list_path) as infile:
    for line in infile:
        if 'id' not in line:
            subjects.append(line.strip())

models = [
    {'field': 'reward_lr,inverse_temp,reward_prior,decision_thresh,starting_bias,drift_baseline,drift_mod,nondecision_time', 'drift_mapping': 'action_prob', 'bias_mapping': '', 'thresh_mapping': ''},
    {'field': 'reward_lr,inverse_temp,reward_prior,decision_thresh,drift,bias_mod,nondecision_time', 'drift_mapping': '', 'bias_mapping': 'action_prob', 'thresh_mapping': ''},
    {'field': 'reward_lr,inverse_temp,reward_prior,decision_thresh,bias_mod,drift_baseline,drift_mod,nondecision_time', 'drift_mapping': 'action_prob', 'bias_mapping': 'action_prob', 'thresh_mapping': ''},

]

for index, model in enumerate(models, start=1):
    combined_results_dir = os.path.join(result_stem, f"model{index}")
    drift_mapping = model['drift_mapping']
    bias_mapping = model['bias_mapping']
    thresh_mapping = model['thresh_mapping']
    field = model['field']

    k = 0

    for subject in subjects:
        # if k ==3:
        #     break
    
        if not os.path.exists(f"{combined_results_dir}/logs"):
            os.makedirs(f"{combined_results_dir}/logs")
            print(f"Created results-logs directory {combined_results_dir}/logs")
        
        ssub_path = '/media/labs/rsmith/lab-members/cgoldman/change_point_detection/scripts/CPD_scripts_DDM/CPD_bash.ssub'
        stdout_name = f"{combined_results_dir}/logs/CPD-%J-{subject}.stdout"
        stderr_name = f"{combined_results_dir}/logs/CPD-%J-{subject}.stderr"

        jobname = f'CPD-Model-{index}-{subject}'
        os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} \"{subject}\" \"{combined_results_dir}\" \"{field}\" \"{drift_mapping}\" \"{bias_mapping}\" \"{thresh_mapping}\"")

        print(f"SUBMITTED JOB [{jobname}]")
        k = k+1
    

 
    
# ###python3 /media/labs/rsmith/lab-members/cgoldman/change_point_detection/scripts/CPD_scripts_DDM/CPD_fitting.py /media/labs/rsmith/lab-members/cgoldman/change_point_detection/fitting_output/RL_DDM

# joblist | grep GNG | grep -Po 13..... | xargs -n1 scancel