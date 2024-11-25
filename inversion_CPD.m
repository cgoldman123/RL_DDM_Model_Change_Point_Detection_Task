% Model fitting script for CPD task

function DCM = inversion_CPD(DCM)

% MDP inversion using Variational Bayes
% FORMAT [DCM] = spm_dcm_mdp(DCM)

% If simulating - comment out section on line 196
% If not simulating - specify subject data file in this section 

%
% Expects:
%--------------------------------------------------------------------------
% DCM.MDP   % MDP structure specifying a generative model
% DCM.field % parameter (field) names to optimise
% DCM.U     % cell array of outcomes (stimuli)
% DCM.Y     % cell array of responses (action)
%
% Returns:
%--------------------------------------------------------------------------
% DCM.M     % generative model (DCM)
% DCM.Ep    % Conditional means (structure)
% DCM.Cp    % Conditional covariances
% DCM.F     % (negative) Free-energy bound on log evidence
% 
% This routine inverts (cell arrays of) trials specified in terms of the
% stimuli or outcomes and subsequent choices or responses. It first
% computes the prior expectations (and covariances) of the free parameters
% specified by DCM.field. These parameters are log scaling parameters that
% are applied to the fields of DCM.MDP. 
%
% If there is no learning implicit in multi-trial games, only unique trials
% (as specified by the stimuli), are used to generate (subjective)
% posteriors over choice or action. Otherwise, all trials are used in the
% order specified. The ensuing posterior probabilities over choices are
% used with the specified choices or actions to evaluate their log
% probability. This is used to optimise the MDP (hyper) parameters in
% DCM.field using variational Laplace (with numerical evaluation of the
% curvature).
%
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_mdp.m 7120 2017-06-20 11:30:30Z spm $

% OPTIONS
%--------------------------------------------------------------------------
ALL = false;

% prior expectations and covariance
%--------------------------------------------------------------------------
% parameter list:
% reward_lr
% latent_lr
% new_latent_lr
% inverse_temp
prior_variance = 1;

for i = 1:length(DCM.field)
    field = DCM.field{i};
    try
        param = DCM.MDP.(field);
        param = double(~~param);
    catch
        param = 1;
    end
    if ALL
        pE.(field) = zeros(size(param));
        pC{i,i}    = diag(param);
    else
        if any(strcmp(field,{'reward_lr','starting_bias', 'drift_mod'}))
            pE.(field) = log(DCM.MDP.(field)/(1-DCM.MDP.(field)));           
            pC{i,i}    = 0.1;            
        elseif any(strcmp(field,{'inverse_temp','decision_thresh'}))
            pE.(field) = log(DCM.MDP.(field));             
            pC{i,i}    = 1;
        elseif any(strcmp(field,{'reward_prior', 'drift_baseline'}))
            pE.(field) = DCM.MDP.(field)   ;             
            pC{i,i}    = 0.5;               
        else
            error("Specify the param to transform!");
        end
    end
end

pC      = spm_cat(pC);

% model specification
%--------------------------------------------------------------------------
M.L     = @(P,M,U,Y)spm_mdp_L(P,M,U,Y);  % log-likelihood function
M.pE    = pE;                            % prior means (parameters)
M.pC    = pC;                            % prior variance (parameters)
M.settings = DCM.settings;

% Variational Laplace
%--------------------------------------------------------------------------
[Ep,Cp,F] = spm_nlsi_Newton(M,DCM.U,DCM.Y);

%% remember to comment this out
% Ep = pE;
% Cp = pC;
% F = 0;
%%


% Store posterior densities and log evidnce (free energy)
%--------------------------------------------------------------------------
DCM.M   = M;
DCM.Ep  = Ep;
DCM.Cp  = Cp;
DCM.F   = F;


return
end

function [L] = spm_mdp_L(P,M,U,Y)
% log-likelihood function
% FORMAT L = spm_mdp_L(P,M,U,Y)
% P    - parameter structure
% M    - generative model
% U    - inputs
% Y    - observed repsonses
%__________________________________________________________________________

if ~isstruct(P); P = spm_unvec(P,M.pE); end

% multiply parameters in MDP
%--------------------------------------------------------------------------
% mdp   = M.mdp;

field = fieldnames(M.pE);
for i = 1:length(field)
    if any(strcmp(field{i},{'reward_lr','starting_bias', 'drift_mod'}))
        params.(field{i}) = 1/(1+exp(-P.(field{i}))); 
    elseif any(strcmp(field{i},{'inverse_temp','decision_thresh'}))
        params.(field{i}) = exp(P.(field{i}));           
    elseif any(strcmp(field{i},{'reward_prior', 'drift_baseline'}))
        params.(field{i}) = P.(field{i});
    else
        error("param not transformed");
    end
end


trials = U;
settings = M.settings;
settings.sim = 0;
action_probabilities = CPD_RL_DDM_model(params, trials,settings);    
choices = action_probabilities.patch_choice_action_prob;
rt_pdf = action_probabilities.dot_motion_rt_pdf;
all_values = [choices(:); rt_pdf(:)];
% Remove NaN values
all_values = all_values(~isnan(all_values));
% Take the log of the remaining values and sum them
L = sum(log(all_values));

 fprintf('LL: %f \n',L)
%  fprintf('Average choice probability: %f \n',average_action_prob)
% fprintf('Average Accuracy: %f \n',average_model_acc)
end





