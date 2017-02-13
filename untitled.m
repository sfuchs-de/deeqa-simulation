nsize=50;
x=rand(nsize,1);
cont_value=log(sum(exp(x)));
ccp=exp(x)./sum(exp(x));
x_mean=x;
x_mean(:)=mean(x);

%% Can we approximate this knowing only the 
%% the cov/var matrix and the mean utility
log_sum_exp = @(x) log(sum(exp(x)));
ccp = @(x) exp(x)./sum(exp(x));

cont_value_approx_first_order=log_sum_exp(x_mean)+...
    ccp(x_mean)'*(x-x_mean);
cont_value_approx_second_order=log_sum_exp(x_mean)+...
    ccp(x_mean)'*(x-x_mean)+;

