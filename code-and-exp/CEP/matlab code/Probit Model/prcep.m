function [logl, KL, auc, logls, KLs, aucs, time] = prcep(train, test, ts_mean, ts_var, cfg)

threshold = cfg.tol;
rho = cfg.rho;
max_iter = cfg.max_iter;

y = train.y;
x = train.x;
N = size(y,1);
D = size(x,2);
M = size(test.y, 1);
iter = 1;



% intermediate record
intermediate_record = struct('joint_var', {}, 'joint_mean', {}, 'time', {});

logls = [];
KLs = [];
aucs = [];
time = [];

% initialize
precision_list = ones(N,D) * 1e-6;
prod_list = zeros(N, D);
new_precision = zeros(N,D);
new_prod = zeros(N,D);

% calculate joint
joint_precision = sum(precision_list) + 1;
joint_prod = sum(prod_list);
joint_mean = (1 ./ joint_precision) .* joint_prod;

tic;
while true
    % q
    q_precision = repmat(joint_precision, N, 1) - precision_list;
    tmp = repmat(joint_precision .* joint_mean, N, 1);
    q_var = 1 ./ q_precision;
    q_mean = q_var .* (tmp - prod_list);
    

    for d = 1 : D
        idx = setdiff(1:D, d);

        c1 = (2 * y - 1) ./ sqrt(1 + x(:,d).^2 .* q_var(:,d));
        c2 = sum((repmat(joint_mean(idx), N, 1) .* x(:,idx)),2) + x(:,d) .* q_mean(:,d);
        
        cdfln = normcdfln(c1' .* c2');
        pdfln = mvnormpdfln(c1' .* c2');
        pdc = exp(pdfln - cdfln)';
        
        dmu = pdc .* c1 .* x(:,d);
        dsig = -0.5 * pdc .* (c1.^3) .* c2 .* (x(:,d).^2);
        
        new_joint_var = q_var(:,d) - q_var(:,d).^2 .* (dmu.^2 - 2 * dsig);
        new_joint_precision = 1 ./ new_joint_var;
        new_joint_mean = q_mean(:,d) + q_var(:,d) .* dmu;
        
        new_precision(:,d) = new_joint_precision - q_precision(:,d);
%         new_mean(:,d) = 1 ./ new_precision(:,d) .* (new_joint_precision .* new_joint_mean - q_precision(:,d) .* q_mean(:,d));
        new_prod(:,d) = new_joint_precision .* new_joint_mean - q_precision(:,d) .* q_mean(:,d);
        % correction
        tmp = find(new_precision(:,d) <=0);
        new_precision(tmp, d) = 1e-6;
        new_prod(tmp, d) = prod_list(tmp, d);
    end
    
    time(iter) = toc;
    
    precision_list = precision_list * (1 - rho) + new_precision * rho;
    old_prod = prod_list;
    prod_list = prod_list * (1 - rho) + new_prod * rho;
    diff = mean(sum((old_prod - prod_list).^2, 2));

    % calculate joint
    joint_precision = sum(precision_list) + 1;
    joint_prod = sum(prod_list);
    joint_mean = (1 ./ joint_precision) .* joint_prod;

    % KL divergence
    joint_var = diag(1 ./ joint_precision);    
    KL = 0.5 * (logdet(joint_var) -  logdet(ts_var) + trace(joint_var \ ts_var) + (joint_mean' - ts_mean)' * inv(joint_var) * (joint_mean' - ts_mean) - D);
    
    % log likelihood
    
    t1 = (2* y - 1) .* (x * joint_mean');
    t2 = sqrt(1 + x.^2 * (1./ joint_precision)');
    train_logl = mean(normcdfln(t1 ./ t2));

    t1 = (2* test.y - 1) .* (test.x * joint_mean');
    t2 = sqrt(1 + test.x.^2 * (1./ joint_precision)');
    
    p = normcdf(test.x * joint_mean');
    [~,~,~,auc] = perfcurve(test.y,p,1);
    
    tmp = normcdfln(t1 ./ t2);
    logl = mean(tmp);
    
    % record
    KLs(end+1) = KL;
    logls(end+1) = logl;
    aucs(end+1) = auc;
    
    r.joint_var = joint_var;
    r.joint_mean = joint_mean;
    r.time = time(iter);
    intermediate_record(end+1) = r;
    
    disp(sprintf('cep-- iter:%d, diff:%.8f, train_logl:%.8f, test_logl:%.8f, auc:%.8f,  KL:%.8f',iter, diff, train_logl, logl ,auc, KL));
    
    if diff < threshold || iter > max_iter 
        save('./intermediate/prcep.mat', 'intermediate_record');
        break;
    end
    iter = iter + 1;
end
end

