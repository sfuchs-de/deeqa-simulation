% =========================================================================
% SIMULATING DATA according to Market Penetration Model, endogenous
% knowledge
% by Simon Fuchs, Feb 2017
%
% INPUT:
% OUTPUT:
%         Results, structure
% USES:   GMMEstimation
%
% =========================================================================

%% SETUP
clear all
nregions=2;
ndest=3;
nsector=2;
noccupations=2;
nfirms=5;
time=10;
error=5;
while error>0,
    nworkers_white=round(rand(nregions,nsector)*50)+1;
    nworkers_blue=round(rand(nregions,nsector)*500)+1;
    nworkers_exp=round(rand(nregions,nsector,ndest)*5)+1;
    error_temp=nworkers_white-sum(nworkers_exp,3);
    error_temp(error_temp>0)=0;
    error=sum(sum(abs(error_temp)));
end
export_market_size=rand(ndest,nsector)*1000;
fixed_cost=rand(ndest,1);
export_market_price_ind=rand(ndest,nsector)*5;
sigma=rand(nsector,1)+1;
tau=rand(nregions,ndest,nsector)+1;

%Firm Productivity
varphi=zeros(nfirms,nsector,nregions);
for i=1:nregions,
    varphi(:,:,i) = lognrnd(.5,.1,nfirms,nsector);
end

beta=8;
eta=.7; %CD Share of Blue collar workers in production
delta=.1; % CD Share of experience in marketing
gamma=.1; % CD Share of blue collar in marketing
delta_1=.3; %Share of workers learning
delta_2=.05; %Share of workers forgetting

%Assign to model object
Model.nregions=nregions;
Model.ndest=ndest;
Model.nsector=nsector;
Model.noccupations=noccupations;
Model.nfirms=nfirms;
Model.nworkers_white=nworkers_white;
Model.nworkers_blue=nworkers_blue;
Model.nworkers_exp=nworkers_exp;
Model.export_market_size=export_market_size;
Model.fixed_cost=fixed_cost;
Model.export_market_price_ind=export_market_price_ind;
Model.sigma=sigma;
Model.tau=tau;


Model.varphi=varphi;
Model.beta=beta;
Model.eta=eta; %CD Share of Blue collar workers in production
Model.delta=delta; % CD Share of experience in marketing
Model.gamma=gamma; % CD Share of blue collar in marketing
Model.delta_1=delta_1; %Share of workers learning
Model.delta_2=delta_2; %Share of workers forgetting



%% STATIC LABOR MARKET EQUILIBRIUM
%Initial wage guess
[wage_blue,wage_white,wage_exp,quant_prod,nworkers_exp_upd,lab_demand_white] = Static_Eq(Model);
if sum(sum(isnan(wage_blue)))==1 || sum(sum(isnan(wage_white)))==1 || sum(sum(sum(isnan(wage_exp))))==1,
    disp('Problem with wage subroutine');
end

%Update knowledge premia subject to knowledge creation
Model.nworkers_exp=nworkers_exp_upd;
[wage_blue,wage_white,wage_exp,quant_prod] = Static_Eq(Model);



%Output panel
worker_panel_white=zeros(sum(sum(nworkers_white)),4+ndest,time);
worker_panel_blue=zeros(sum(sum(nworkers_blue)),3,time);
firm_panel=zeros(nfirms,ndest,nsector,nregions,time);

firm_panel(:,:,:,:,1)=quant_prod;

m=1;
for j=1:nregions,
    for l=1:nsector,
        stor1=nworkers_blue(j,l);
        stor2=j;
        stor3=l;
        k=0;
        while k<stor1;
            worker_panel_blue(m,1,1)=stor2; %Regions
            worker_panel_blue(m,2,1)=stor3; %Sector
            worker_panel_blue(m,3,1)=wage_blue(stor2,stor3); %Wage
            k=k+1;
            m=m+1;
        end
    end
end

m=1;
for j=1:nregions,
    for l=1:nsector,
        stor1=nworkers_white(j,l);
        stor2=j;
        stor3=l;
        k=0;
        while k<stor1;
            worker_panel_white(m,1,1)=stor2; %Regions
            worker_panel_white(m,2,1)=stor3; %Sector
            worker_panel_white(m,3,1)=wage_white(stor2,stor3); %Wage
            k=k+1;
            m=m+1;
        end
    end
end



for j=1:nregions,
    for l=1:nsector,
        for n=1:ndest,
            k=0;
            stor1=nworkers_exp(j,l,n);
            m=1;
            while k<stor1;
                stor2=j;
                stor3=l;
                stor4=n;
                if worker_panel_white(m,1,1)==stor2 && worker_panel_white(m,2,1)==stor3 && worker_panel_white(m,4,1)~=1;
                    worker_panel_white(m,3,1)=wage_white(stor2,stor3)+wage_exp(j,l,n); %Wage
                    worker_panel_white(m,4,1)=1;
                    worker_panel_white(m,4+n,1)=1;
                    k=k+1;
                end
                m=m+1;
            end
        end
    end
end




%% INTERMEDIATE STEP: KNOWLEDGE CREATION

nworkers_exp_old=nworkers_exp;
nworkers_exp=nworkers_exp_upd; %Actual knowledge creation in jobs, changes knowledge supply

%Output into panel (more complex)


for j=1:nregions,
    for l=1:nsector,
        for n=1:ndest,
            k=0;
            stor1=abs(nworkers_exp(j,l,n)-nworkers_exp_old(j,l,n));
            m=1;
            while k<stor1;
                stor2=j;
                stor3=l;
                stor4=n;
                if nworkers_exp(j,l,n)<nworkers_exp_old(j,l,n), %If less knowledgeable workers then make some forget
                    if worker_panel_white(m,1,1)==stor2 && worker_panel_white(m,2,1)==stor3 && worker_panel_white(m,4+n,1)==1 && worker_panel_white(m,4,1)==1,
                        worker_panel_white(m,4,1)=0;
                        worker_panel_white(m,4+n,1)=0;
                        k=k+1;
                    end
                end
                if nworkers_exp(j,l,n)>nworkers_exp_old(j,l,n), %If more knowledgeable workers then add workers
                    if worker_panel_white(m,1,1)==stor2 && worker_panel_white(m,2,1)==stor3 && worker_panel_white(m,4+n,1)==0 && worker_panel_white(m,4,1)==0,
                        worker_panel_white(m,4,1)=1;
                        worker_panel_white(m,4+n,1)=1;
                        k=k+1;
                    end
                end
                if nworkers_exp(j,l,n)==nworkers_exp_old(j,l,n),
                    k=k+1;
                end
                m=m+1;
            end
            test_obj(j,l,n)=k;
        end
    end
end
test_obj-abs(nworkers_exp-nworkers_exp_old)
clear test_obj


for j=1:nregions,
    for l=1:nsector,
        for n=1:ndest,
            k=0;
            stor1=nworkers_exp(j,l,n);
            m=1;
            while k<stor1;
                stor2=j;
                stor3=l;
                stor4=n;
                if worker_panel_white(m,1,1)==stor2 && worker_panel_white(m,2,1)==stor3 && worker_panel_white(m,4+n,1)==1,
                    worker_panel_white(m,3,1)=wage_white(stor2,stor3)+wage_exp(j,l,n); %Wage
                    k=k+1;
                end
                m=m+1;
            end
            test_obj(j,l,n)=k;
        end
    end
end

%checked and correct


%% LABOR MOBILITY DECISION

%Configuration
tau_sec=rand(nsector,nsector)+10;
tau_geo=rand(nregions,nregions)+10;
for i=1:nregions,
    tau_geo(i,i)=0;
end
for i=1:nsector,
    tau_sec(i,i)=0;
end
nu=4;
beta=0.9;

nworkers_blue_old=nworkers_blue;
nworkers_white_old=nworkers_white;


%Expected wages have to be consistent with general equilibrium future wages
error=6;
nworkers_blue_temp=nworkers_blue;
nworkers_white_temp=nworkers_white;
nworkers_exp_temp=nworkers_exp;
while error>1,
    [nworkers_blue_temp,nworkers_blue_ind] = LaborLoop_adj(wage_blue, nworkers_blue, tau_sec, tau_geo, nu, beta,nregions,nsector);
    [nworkers_white_temp,nworkers_white_ind] = LaborLoop_adj(wage_white, nworkers_white-sum(nworkers_exp,3), tau_sec, tau_geo, nu, beta,nregions,nsector);
    for i=1:ndest,
        [nworkers_exp_temp(:,:,i),nworkers_white_exp_ind(:,:,:,:,i)] = LaborLoop_adj(wage_white+wage_exp(:,:,i), nworkers_exp(:,:,i), tau_sec, tau_geo, nu, beta,nregions,nsector);
    end
    Model.nworkers_white=.9*Model.nworkers_white+.1*(nworkers_white_temp+sum(nworkers_exp_temp,3));
    Model.nworkers_blue=.9*Model.nworkers_blue+.1*nworkers_blue_temp;
    Model.nworkers_exp=.9*Model.nworkers_exp+.1*nworkers_exp_temp;
    wage_blue_old=wage_blue;
    [wage_blue,wage_white,wage_exp,quant_prod,nworkers_exp_upd,lab_demand_white] = Static_Eq(Model);
    error=sum(sum(abs(Model.nworkers_blue-nworkers_blue_temp)));
end

nworkers_white=nworkers_white_temp;
nworkers_blue=nworkers_blue_temp;
nworkers_exp=nworkers_exp_temp;
Model.nworkers_white=nworkers_white+sum(nworkers_exp,3);
nworkers_white=nworkers_white+sum(nworkers_exp,3);
Model.nworkers_blue=nworkers_blue;
Model.nworkers_exp=nworkers_exp;
[wage_blue,wage_white,wage_exp,quant_prod,nworkers_exp_upd,lab_demand_white] = Static_Eq(Model);



Model.nworkers_exp=nworkers_exp_upd;

[wage_blue,wage_white,wage_exp,quant_prod] = Static_Eq(Model); %Adjust wages to reflect knowledge creation



% Storage of results
worker_panel_store_2=worker_panel_blue(:,:,1);
for i=1:nregions,
    for j=1:nregions,
        for r=1:nsector,
            for q=1:nsector,
                m=1;
                stor1=nworkers_blue_ind(j,q,i,r);
                stor2=i;
                stor3=r;
                stor4=j;
                stor5=q;
                k=0;
                while k<stor1;
                    if worker_panel_blue(m,1,1)==stor2 && worker_panel_blue(m,2,1)==stor3;
                        worker_panel_blue(m,1,2)=stor4; %Regions
                        worker_panel_blue(m,2,2)=stor5; %Sector
                        worker_panel_blue(m,3,2)=wage_blue(stor4,stor5); %Wage
                        worker_panel_blue(m,1,1)=999;
                        worker_panel_blue(m,2,1)=999;
                        k=k+1;
                    end
                    m=m+1;
                end
                test_obj(j,q,i,r)=k;
            end
        end
    end
end
worker_panel_blue(:,:,1)=worker_panel_store_2;

%
%
% clear test_obj
% %Checking numbers of experienced workers
% for j=1:nregions,
%     for l=1:nsector,
%         k=0;
%         for m=1:size(worker_panel_blue,1),
%             if worker_panel_blue(m,1,1)==j && worker_panel_blue(m,2,1)==l,
%                 k=k+1;
%             end
%         end
%         test_obj1(j,l)=k;
%     end
% end
%
% test_obj1-squeeze(sum(sum(nworkers_blue_ind)))
%
%
% %Checking numbers of experienced workers
% for j=1:nregions,
%     for l=1:nsector,
%         k=0;
%         for m=1:size(worker_panel_blue,1),
%             if worker_panel_blue(m,1,2)==j && worker_panel_blue(m,2,2)==l,
%                 k=k+1;
%             end
%         end
%         test_obj2(j,l)=k;
%     end
% end
%
% test_obj2-sum(sum(nworkers_blue_ind,4),3)














clear test_obj
worker_panel_store=worker_panel_white(:,:,1);

%Diagnostics
sum(sum(sum(nworkers_exp_old)))
size(worker_panel_white,1)-sum(sum(sum(sum(nworkers_white_ind))))
sum(worker_panel_white(:,4,1))
sum(sum(sum(nworkers_exp)))
sum(sum(sum(sum(sum(nworkers_white_exp_ind)))))

for i=1:nregions,
    for j=1:nregions,
        for r=1:nsector,
            for q=1:nsector,
                m=1;
                stor1=round(nworkers_white_ind(j,q,i,r));
                stor2=i;
                stor3=r;
                stor4=j;
                stor5=q;
                k=0;
                while k<stor1;
                    if worker_panel_white(m,1,1)==stor2 && worker_panel_white(m,2,1)==stor3 && worker_panel_white(m,4,1)~=1,
                        worker_panel_white(m,1,2)=stor4; %Regions
                        worker_panel_white(m,2,2)=stor5; %Sector
                        worker_panel_white(m,3,2)=wage_white(stor4,stor5); %Wage
                        worker_panel_white(m,1,1)=999;
                        worker_panel_white(m,2,1)=999;
                        k=k+1;
                    end
                    m=m+1;
                end
                test_obj(j,q,i,r)=k;
            end
        end
    end
end
worker_panel_white(:,:,1)=worker_panel_store;
clear worker_panel_store worker_panel_store_2;





















worker_panel_store=worker_panel_white(:,:,1);
for i=1:nregions,
    for j=1:nregions,
        for r=1:nsector,
            for q=1:nsector,
                for p=1:ndest,
                    m=1;
                    stor1=round(nworkers_white_exp_ind(j,q,i,r,p));
                    stor2=i;
                    stor3=r;
                    stor4=j;
                    stor5=q;
                    r;
                    k=0;
                    while k<stor1;
                        if worker_panel_white(m,1,1)==stor2 && worker_panel_white(m,2,1)==stor3 && worker_panel_white(m,4+p,1)~=0,
                            worker_panel_white(m,1,2)=stor4; %Regions
                            worker_panel_white(m,2,2)=stor5; %Sector
                            worker_panel_white(m,3,2)=wage_white(stor4,stor5)+wage_exp(stor4,stor5,p); %Wage
                            worker_panel_white(m,4,2)=1;
                            worker_panel_white(m,4+p,2)=1;
                            worker_panel_white(m,1,1)=999;
                            worker_panel_white(m,2,1)=999;
                            k=k+1;
                        end
                        m=m+1;
                    end
                end
            end
        end
    end
end
worker_panel_white(:,:,1)=worker_panel_store;
clear worker_panel_store worker_panel_store_2;

clear test_obj
%Checking numbers of experienced workers
for j=1:nregions,
    for l=1:nsector,
        for n=1:ndest,
            k=0;
            for m=1:size(worker_panel_white,1),
                if worker_panel_white(m,1,2)==j && worker_panel_white(m,2,2)==l && worker_panel_white(m,4+n,2)==1 && worker_panel_white(m,4,2)==1,
                    k=k+1;
                end
            end
            test_obj(j,l,n)=k;
        end
    end
end



%% INTERMEDIATE STEP: KNOWLEDGE CREATION
%Checking numbers of experienced workers

nworkers_exp_old=nworkers_exp;
nworkers_exp=nworkers_exp_upd; %Actual knowledge creation in jobs, changes knowledge supply

%Output into panel (more complex)
nworkers_exp-nworkers_exp_old;
clear test_obj
for j=1:nregions,
    for l=1:nsector,
        for n=1:ndest,
            k=0;
            stor1=abs(nworkers_exp(j,l,n)-nworkers_exp_old(j,l,n));
            m=1;
            while k<stor1;
                stor2=j;
                stor3=l;
                stor4=n;
                if nworkers_exp(j,l,n)<nworkers_exp_old(j,l,n), %If less knowledgeable workers then make some forget
                    if worker_panel_white(m,1,2)==stor2 && worker_panel_white(m,2,2)==stor3 && worker_panel_white(m,4+n,2)==1 && worker_panel_white(m,4,2)==1,
                        worker_panel_white(m,4,2)=0;
                        worker_panel_white(m,4+n,2)=0;
                        k=k+1;
                    end
                end
                if nworkers_exp(j,l,n)>nworkers_exp_old(j,l,n), %If more knowledgeable workers then add workers
                    if worker_panel_white(m,1,2)==stor2 && worker_panel_white(m,2,2)==stor3 && worker_panel_white(m,4+n,2)==0 && worker_panel_white(m,4,2)==0,
                        worker_panel_white(m,4,2)=1;
                        worker_panel_white(m,4+n,2)=1;
                        k=k+1;
                    end
                end
                if nworkers_exp(j,l,n)==nworkers_exp_old(j,l,n),
                    k=k+1;
                end
                m=m+1;
            end
            test_obj(j,l,n)=k;
        end
    end
end
test_obj-abs(nworkers_exp-nworkers_exp_old)
%clear test_obj
%checked and correct
clear test_obj
%Checking numbers of experienced workers
for j=1:nregions,
    for l=1:nsector,
        for n=1:ndest,
            k=0;
            for m=1:size(worker_panel_white,1),
                if worker_panel_white(m,1,2)==j && worker_panel_white(m,2,2)==l && worker_panel_white(m,4+n,2)==1 && worker_panel_white(m,4,2)==1,
                    k=k+1;
                end
            end
            test_obj(j,l,n)=k;
        end
    end
end

test_obj-nworkers_exp

%Problem: Only 1 experienced worker for 1,2,1 but wants 3 - nworkers_exp
%inconsistent with worker_panel_white(:,:,2) Could be due to previous loop
%adjusting the numbers or nworkers_exp labor adjustment loop getting the
%numbers wrong.
for j=1:nregions,
    for l=1:nsector,
        for n=1:ndest,
            k=0;
            stor1=nworkers_exp(j,l,n);
            m=1;
            while k<stor1;
                stor2=j;
                stor3=l;
                stor4=n;
                if worker_panel_white(m,1,2)==stor2 && worker_panel_white(m,2,2)==stor3 && worker_panel_white(m,4+n,2)==1 && worker_panel_white(m,4,2)==1,
                    worker_panel_white(m,3,2)=wage_white(stor2,stor3)+wage_exp(j,l,n); %Wage
                    k=k+1;
                end
                m=m+1;
            end
            %test_obj(j,l,n)=k;
        end
    end
end


% Checked: 22/02 - 13:18




for t=3:10,
    
    %% LABOR MOBILITY DECISION
    Model.export_market_size=Model.export_market_size+rand(ndest,nsector)*10-5;
    
    
    
    
    
    nworkers_blue_old=nworkers_blue;
    nworkers_white_old=nworkers_white;
    
    
    %Expected wages have to be consistent with general equilibrium future wages
    error=6;
    nworkers_blue_temp=nworkers_blue;
    nworkers_white_temp=nworkers_white;
    nworkers_exp_temp=nworkers_exp;
    while error>1,
        [nworkers_blue_temp,nworkers_blue_ind] = LaborLoop_adj(wage_blue, nworkers_blue, tau_sec, tau_geo, nu, beta,nregions,nsector);
        [nworkers_white_temp,nworkers_white_ind] = LaborLoop_adj(wage_white, nworkers_white-sum(nworkers_exp,3), tau_sec, tau_geo, nu, beta,nregions,nsector);
        for i=1:ndest,
            [nworkers_exp_temp(:,:,i),nworkers_white_exp_ind(:,:,:,:,i)] = LaborLoop_adj(wage_white+wage_exp(:,:,i), nworkers_exp(:,:,i), tau_sec, tau_geo, nu, beta,nregions,nsector);
        end
        Model.nworkers_white=.9*Model.nworkers_white+.1*(nworkers_white_temp+sum(nworkers_exp_temp,3));
        Model.nworkers_blue=.9*Model.nworkers_blue+.1*nworkers_blue_temp;
        Model.nworkers_exp=.9*Model.nworkers_exp+.1*nworkers_exp_temp;
        wage_blue_old=wage_blue;
        [wage_blue,wage_white,wage_exp,quant_prod,nworkers_exp_upd,lab_demand_white] = Static_Eq(Model);
        error=sum(sum(abs(Model.nworkers_blue-nworkers_blue_temp)))
    end
    
    nworkers_white=nworkers_white_temp;
    nworkers_blue=nworkers_blue_temp;
    nworkers_exp=nworkers_exp_temp;
    Model.nworkers_white=nworkers_white+sum(nworkers_exp,3);
    nworkers_white=nworkers_white+sum(nworkers_exp,3);
    Model.nworkers_blue=nworkers_blue;
    Model.nworkers_exp=nworkers_exp;
    [wage_blue,wage_white,wage_exp,quant_prod,nworkers_exp_upd,lab_demand_white] = Static_Eq(Model);
    
    
    
    
    
    
    
    
    % Storage of results
    worker_panel_store_2=worker_panel_blue(:,:,t-1);
    for i=1:nregions,
        for j=1:nregions,
            for r=1:nsector,
                for q=1:nsector,
                    m=1;
                    stor1=nworkers_blue_ind(j,q,i,r);
                    stor2=i;
                    stor3=r;
                    stor4=j;
                    stor5=q;
                    k=0;
                    while k<stor1;
                        if worker_panel_blue(m,1,t-1)==stor2 && worker_panel_blue(m,2,t-1)==stor3;
                            worker_panel_blue(m,1,t)=stor4; %Regions
                            worker_panel_blue(m,2,t)=stor5; %Sector
                            worker_panel_blue(m,3,t)=wage_blue(stor4,stor5); %Wage
                            worker_panel_blue(m,1,t-1)=999;
                            worker_panel_blue(m,2,t-1)=999;
                            k=k+1;
                        end
                        m=m+1;
                    end
                    test_obj(j,q,i,r)=k;
                end
            end
        end
    end
    worker_panel_blue(:,:,t-1)=worker_panel_store_2;
    
    clear test_obj
    worker_panel_store=worker_panel_white(:,:,t-1);
    
    
    
    for i=1:nregions,
        for j=1:nregions,
            for r=1:nsector,
                for q=1:nsector,
                    m=1;
                    stor1=round(nworkers_white_ind(j,q,i,r));
                    stor2=i;
                    stor3=r;
                    stor4=j;
                    stor5=q;
                    k=0;
                    while k<stor1;
                        if worker_panel_white(m,1,t-1)==stor2 && worker_panel_white(m,2,t-1)==stor3 && worker_panel_white(m,4,t-1)~=1,
                            worker_panel_white(m,1,t)=stor4; %Regions
                            worker_panel_white(m,2,t)=stor5; %Sector
                            worker_panel_white(m,3,t)=wage_white(stor4,stor5); %Wage
                            worker_panel_white(m,1,t-1)=999;
                            worker_panel_white(m,2,t-1)=999;
                            k=k+1;
                        end
                        m=m+1;
                    end
                    test_obj(j,q,i,r)=k;
                end
            end
        end
    end
    worker_panel_white(:,:,t-1)=worker_panel_store;
    clear worker_panel_store worker_panel_store_2;
    
    clear test_obj
    %Checking numbers of experienced workers
    for j=1:nregions,
        for l=1:nsector,
            k=0;
            for m=1:size(worker_panel_white,1),
                if worker_panel_white(m,1,t-1)==j && worker_panel_white(m,2,t-1)==l && worker_panel_white(m,4,t-1)~=0,
                    k=k+1;
                end
            end
            test_obj(j,l)=k;
        end
    end
    
    
    worker_panel_store=worker_panel_white(:,:,t-1);
    for i=1:nregions,
        for j=1:nregions,
            for r=1:nsector,
                for q=1:nsector,
                    for p=1:ndest,
                        m=1;
                        stor1=round(nworkers_white_exp_ind(j,q,i,r,p));
                        stor2=i;
                        stor3=r;
                        stor4=j;
                        stor5=q;
                        r;
                        k=0;
                        while k<stor1;
                            if worker_panel_white(m,1,t-1)==stor2 && worker_panel_white(m,2,t-1)==stor3 && worker_panel_white(m,4+p,t-1)~=0,
                                worker_panel_white(m,1,t)=stor4; %Regions
                                worker_panel_white(m,2,t)=stor5; %Sector
                                worker_panel_white(m,3,t)=wage_white(stor4,stor5)+wage_exp(stor4,stor5,p); %Wage
                                worker_panel_white(m,4,t)=1;
                                worker_panel_white(m,4+p,t)=1;
                                worker_panel_white(m,1,t-1)=999;
                                worker_panel_white(m,2,t-1)=999;
                                k=k+1;
                            end
                            m=m+1;
                        end
                    end
                end
            end
        end
    end
    worker_panel_white(:,:,t-1)=worker_panel_store;
    clear worker_panel_store worker_panel_store_2;
    
    clear test_obj
    %Checking numbers of experienced workers
    for j=1:nregions,
        for l=1:nsector,
            for n=1:ndest,
                k=0;
                for m=1:size(worker_panel_white,1),
                    if worker_panel_white(m,1,t)==j && worker_panel_white(m,2,t)==l && worker_panel_white(m,4+n,t)==1 && worker_panel_white(m,4,t)==1,
                        k=k+1;
                    end
                end
                test_obj(j,l,n)=k;
            end
        end
    end
    
    
    
    %% INTERMEDIATE STEP: KNOWLEDGE CREATION
    %Checking numbers of experienced workers
    
    nworkers_exp_old=nworkers_exp;
    nworkers_exp=nworkers_exp_upd; %Actual knowledge creation in jobs, changes knowledge supply
    
    %Output into panel (more complex)
    nworkers_exp-nworkers_exp_old;
    clear test_obj
    for j=1:nregions,
        for l=1:nsector,
            for n=1:ndest,
                k=0;
                stor1=abs(nworkers_exp(j,l,n)-nworkers_exp_old(j,l,n));
                m=1;
                while k<stor1;
                    stor2=j;
                    stor3=l;
                    stor4=n;
                    if nworkers_exp(j,l,n)<nworkers_exp_old(j,l,n), %If less knowledgeable workers then make some forget
                        if worker_panel_white(m,1,t)==stor2 && worker_panel_white(m,2,t)==stor3 && worker_panel_white(m,4+n,t)==1 && worker_panel_white(m,4,t)==1,
                            worker_panel_white(m,4,t)=0;
                            worker_panel_white(m,4+n,t)=0;
                            k=k+1;
                        end
                    end
                    if nworkers_exp(j,l,n)>nworkers_exp_old(j,l,n), %If more knowledgeable workers then add workers
                        if worker_panel_white(m,1,t)==stor2 && worker_panel_white(m,2,t)==stor3 && worker_panel_white(m,4+n,t)==0 && worker_panel_white(m,4,t)==0,
                            worker_panel_white(m,4,t)=1;
                            worker_panel_white(m,4+n,t)=1;
                            k=k+1;
                        end
                    end
                    if nworkers_exp(j,l,n)==nworkers_exp_old(j,l,n),
                        k=k+1;
                    end
                    m=m+1;
                end
                test_obj(j,l,n)=k;
            end
        end
    end
    test_obj-abs(nworkers_exp-nworkers_exp_old)
    %clear test_obj
    %checked and correct
    clear test_obj
    %Checking numbers of experienced workers
    for j=1:nregions,
        for l=1:nsector,
            for n=1:ndest,
                k=0;
                for m=1:size(worker_panel_white,1),
                    if worker_panel_white(m,1,t)==j && worker_panel_white(m,2,t)==l && worker_panel_white(m,4+n,t)==1 && worker_panel_white(m,4,t)==1,
                        k=k+1;
                    end
                end
                test_obj(j,l,n)=k;
            end
        end
    end
    
    test_obj-nworkers_exp
    
    %Problem: Only 1 experienced worker for 1,2,1 but wants 3 - nworkers_exp
    %inconsistent with worker_panel_white(:,:,2) Could be due to previous loop
    %adjusting the numbers or nworkers_exp labor adjustment loop getting the
    %numbers wrong.
    for j=1:nregions,
        for l=1:nsector,
            for n=1:ndest,
                k=0;
                stor1=nworkers_exp(j,l,n);
                m=1;
                while k<stor1;
                    stor2=j;
                    stor3=l;
                    stor4=n;
                    if worker_panel_white(m,1,t)==stor2 && worker_panel_white(m,2,t)==stor3 && worker_panel_white(m,4+n,t)==1 && worker_panel_white(m,4,t)==1,
                        worker_panel_white(m,3,t)=wage_white(stor2,stor3)+wage_exp(j,l,n); %Wage
                        k=k+1;
                    end
                    m=m+1;
                end
                %test_obj(j,l,n)=k;
            end
        end
    end
    
    %Step 8: Saving firm trade
    firm_panel(:,:,:,:,t)=quant_prod;
end
