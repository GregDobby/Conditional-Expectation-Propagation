function [nd, w]= quadrl(numnd)

if numnd == 3 
    nd =[1.73205080756888    0  -1.73205080756888 ];
    w =[0.16666666666667   0.66666666666667   0.16666666666667]';
elseif numnd == 5 
    nd =[ 2.85697001387281   1.35562617997427 ...
            0  -1.35562617997427  -2.85697001387281];
w =[  0.01125741132772   0.22207592200561   0.53333333333334 ...
        0.22207592200561   0.01125741132772]';
elseif numnd == 7
nd = [3.75043971772574   2.36675941073454   ...
    1.15440539473997      0  -1.15440539473997 ...
-2.36675941073454  -3.75043971772574];
w =[   0.00054826885597   0.03075712396759   ...
 0.24012317860501   0.45714285714286   0.24012317860501  ...
0.03075712396759   0.00054826885597]';
elseif numnd == 9
nd = [4.51274586339978   3.20542900285647   2.07684797867783...
 1.02325566378913     0 -1.02325566378913  -2.07684797867783 ...
 -3.20542900285647  -4.51274586339978];
w =[ 0.00002234584401   0.00278914132123   0.04991640676522 ...
 0.24409750289494   0.40634920634921  0.24409750289494 ...
 0.04991640676522   0.00278914132123   0.00002234584401]';
end
