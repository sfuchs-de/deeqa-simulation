function [wage_blue,wage_white,wage_exp,quant_prod,nworkers_exp_upd,lab_demand_white] = Static_Eq(Model)
% =============================================================================================
% Objective Function for Ancient city structural model
%
% INPUT: Params, vector, vector of estimated parameters
%        Model, structure
%        W, matrix, weighting matrix
% OUTPUT: J (objective)
% =============================================================================================
%% DATA INPUT/PROCESS
nregions=Model.nregions;
ndest=Model.ndest;
nsector=Model.nsector;
noccupations=Model.noccupations;
nfirms=Model.nfirms;
nworkers_white=Model.nworkers_white;
nworkers_blue=Model.nworkers_blue;
nworkers_exp=Model.nworkers_exp;
export_market_size=Model.export_market_size;
fixed_cost=Model.fixed_cost;
export_market_price_ind=Model.export_market_price_ind;
sigma=Model.sigma;
tau=Model.tau;
delta_1=Model.delta_1; %Share of workers learning
delta_2=Model.delta_2; %Share of workers forgetting
%Firm Productivity
varphi=Model.varphi;

beta=Model.beta;
eta=Model.eta; %CD Share of Blue collar workers in production
delta=Model.delta; % CD Share of experience in marketing
gamma=Model.gamma; % CD Share of blue collar in marketing


%% STATIC LABOR MARKET EQUILIBRIUM
%Initial wage guess
wage_blue=ones(nregions,nsector);
wage_white=ones(nregions,nsector);
wage_exp=ones(nregions,nsector,ndest);
error=5;

while error>0.001,
    comp_wage_market=zeros(nregions,nsector,ndest);
    comp_wage_prod=wage_blue.^eta.*wage_white.^(1-eta);
    for i=1:ndest,
        comp_wage_market(:,:,i)=wage_blue.^gamma.*wage_exp(:,:,i).^delta.*wage_white.^(1-gamma-delta);
    end
    market_penetration=zeros(nfirms,ndest,nsector,nregions);
    price=zeros(nfirms,nsector,nregions,ndest);
    quant_prod=zeros(nfirms,ndest,nsector,nregions);
    fix_cost_firm=zeros(nfirms,nsector,nregions,ndest);
    for i=1:nfirms,
        for j=1:ndest,
            for s=1:nsector,
                for r=1:nregions;
                    price(i,s,r,j)=sigma(s)/(sigma(s)-1) * tau(r,j,s) * comp_wage_prod(r,s)...
                        * 1/varphi(i,s,r);
                    market_penetration(i,j,s,r)=1-( export_market_size(j,s)/ (sigma(s) * comp_wage_market(r,s,j) * ...
                        fixed_cost(j)) * (price(i,s,r,j)/export_market_price_ind(j,s))...
                        ^(1-sigma(s)))^(-1/beta);
                    if market_penetration(i,j,s,r)<0
                        market_penetration(i,j,s,r)=0;
                    end
                    if isnan(market_penetration(i,j,s,r))
                        market_penetration(i,j,s,r)=0;
                    end
                    quant_prod(i,j,s,r)=market_penetration(i,j,s,r)*...
                        export_market_size(j)*price(i,s,r,j)^(-sigma(s))*export_market_price_ind(j,s)...
                        ^(sigma(s)-1);
                    fix_cost_firm(i,s,r,j)=fixed_cost(j)*(1-(1-market_penetration(i,j,s,r)))^(1-beta)*1/(1-beta);
                end
            end
        end
    end
    
    %Calculate comp labor demand
    quant_prod_firm=sum(quant_prod,2);
    varphi_alt=squeeze(varphi);
    quant_prod_firm=squeeze(quant_prod_firm);
    lab_demand_firm=quant_prod_firm./varphi_alt;
    quant_prod_reg_sec=sum(lab_demand_firm,1);
    quant_prod_reg_sec=squeeze(quant_prod_reg_sec);
    totexp_prod_reg_sec=quant_prod_reg_sec'.*comp_wage_prod;
    fix_cost_reg_sec=sum(fix_cost_firm,1);
    fix_cost_reg_sec=squeeze(fix_cost_reg_sec);
    totexp_market_reg_sec=fix_cost_reg_sec.*comp_wage_market;
    
    %Update wages
    wage_blue_upd=(eta.*totexp_prod_reg_sec+gamma.*sum(totexp_market_reg_sec,3))./(nworkers_blue+1);
    wage_white_upd=((1-eta-delta).*sum(totexp_market_reg_sec,3)+(1-eta).*totexp_prod_reg_sec)./(nworkers_white+1);
    wage_exp_upd=delta.*totexp_market_reg_sec./(nworkers_exp+1);
    wage_blue_old=wage_blue;
    wage_white_old=wage_white;
    wage_exp_old=wage_exp;
    error=sum(sum(abs(wage_blue_upd-wage_blue)));
    
    wage_blue=.7*wage_blue+.3*wage_blue_upd;
    wage_white=.7*wage_white+.3*wage_white_upd;
    wage_exp=.7*wage_exp+.3*wage_exp_upd;
end

for i=1:nfirms,
    for s=1:nsector,
        for r=1:nregions;
            lab_demand_white_firm(i,s,r)=((1-eta-delta).*fix_cost_firm(i,s,r)...
                *comp_wage_market(r,s)+(1-eta).*lab_demand_firm(i,r)*comp_wage_prod(r,s))...
                ./(wage_white(r,s));
        end
    end
end

lab_demand_white=round(sum(lab_demand_white_firm)-1);
lab_demand_white=squeeze(lab_demand_white);
nworkers_exp_upd=floor(delta_1*(lab_demand_white-nworkers_exp)+(1-delta_2)*nworkers_exp);