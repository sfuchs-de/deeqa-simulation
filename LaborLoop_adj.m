function [labor_new,labor_new_ind] = LaborLoop_adj(wages, labor, tau_sec, tau_geo, nu, beta,nregions,nsector)
% =============================================================================================
% Objective Function for Ancient city structural model
%
% INPUT: Params, vector, vector of estimated parameters
%        Model, structure
%        W, matrix, weighting matrix
% OUTPUT: J (objective)
% =============================================================================================
%% DATA INPUT/PROCESS

%Have to do labor re-allocation for each occupation type (i.e.
%blue,white,exp)

%Initiate value function by setting terminal equal to flow utility
ind_utility=zeros(nregions,nsector);
for i=1:nregions,
    for r=1:nsector,
        ind_utility(i,r)=wages(i,r);
    end
end
%Value functions
err=1;
value=ind_utility;

value_ind=zeros(nregions,nsector,nregions,nsector);
%Calculate value functions
while err>.001,
    value_old=value;
    for i=1:nregions,
        for j=1:nregions,
            for r=1:nsector,
                for q=1:nsector,
                    value_ind(i,r,j,q)=(beta*value(j,q)-tau_sec(r,q)-tau_geo(i,j))/nu;
                end
            end
        end
    end
    value_ind=exp(value_ind);
    value_ind_resist=sum(value_ind,4);
    value_ind_resist=sum(value_ind_resist,3);
    for i=1:nregions,
        for r=1:nsector,
            value(i,r)=ind_utility(i,r)+nu*log(value_ind_resist(i,r));
        end
    end
    err_vec=value-value_old;
    err=sum(sum(abs(err_vec)));
end


for i=1:nregions,
    for j=1:nregions,
        for r=1:nsector,
            for q=1:nsector,
                value_ind(i,r,j,q)=(beta*value(j,q)-tau_sec(r,q)-tau_geo(i,j))/nu;
            end
        end
    end
end

value_ind=exp(value_ind);
value_ind_1=sum(value_ind,4);
value_ind_resist=sum(value_ind_1,3);
mig_share=zeros(nregions,nregions,nsector,nsector);

for i=1:nregions,
    for j=1:nregions,
        for r=1:nsector,
            for q=1:nsector,
                mig_share(i,j,r,q)=value_ind(i,r,j,q)/value_ind_resist(i,r);
            end
        end
    end
end
labor_new_ind=zeros(nregions,nsector,nregions,nsector);
for i=1:nregions,
    for j=1:nregions,
        for r=1:nsector,
            for q=1:nsector,
                labor_new_ind(j,q,i,r)=round(mig_share(i,j,r,q)*labor(i,r));
            end
        end
    end
end
adjustment=sum(sum(sum(labor_new_ind,4),3))-sum(sum(labor));
labor_new_ind(1,1,1,1)=labor_new_ind(1,1,1,1)-adjustment;
labor_new=sum(labor_new_ind,4);
labor_new=sum(labor_new,3);
