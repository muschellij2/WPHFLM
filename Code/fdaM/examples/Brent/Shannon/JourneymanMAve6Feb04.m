% Analysis to be performed on Shannon Magari's data (based on "Journeyman.m")
% Prediction of "hrv" - Heart Rate Variability 
% from "pm25.epa" - pm 2.5 level
% -------------------------------------------------------------------
% Created: 6Feb04
% Modified: 6Feb04
%           DATA sets: pm25OneJour.dat
%                      hrvOneJour.dat

addpath ('c:\matlab6p5\fdaM')
addpath ('c:\matlab6p5\fdaM\examples\Brent\Shannon')

%  -----------------------------------------------------------------------
%       Journeyman air pollution data
%  -----------------------------------------------------------------------

%  ----------------  input the data  ------------------------

%% Work day data
hrvmat = load ('hrvOneJour.dat'); 
pm25mat = load ('pm25OneJour.dat'); 
% Work on the subset of the data from time = 10 min to time = 605 min (10
% hours of data)
hrvmat = hrvmat(1:120,:);
pm25mat = pm25mat(1:120,:);

%%%%     DO separate analysis on the log scale and the original scale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Redefining hrvmat and pm25mat to be on the log scale
pm25matLog = log(pm25mat);
hrvmatLog = log(hrvmat);

%% Vars to set up the time matrices
N = size(pm25mat,2); 
K = size(pm25mat,1);
T = 595; 

timevec = linspace(0,T,K)'; 

%% Calculating moving averages of the pm25matLog
%% 15-minute, 30-minute, 60-minute, and 120-minute
format rat; %format as rational numbers
a = 1;
for i=1:N
    for j=1:4
        k= 2^(j-1);
        timeWind(j) = 3*k;
    end
    b = (ones(timeWind(1),1) * 1/timeWind(1))';
    pm25matLog15(:,i) = filter(b,a,pm25matLog(:,i));
    hrvmatLog15(:,i) = filter(b,a,hrvmatLog(:,i));

    b = (ones(timeWind(2),1) * 1/timeWind(2))';
    pm25matLog30(:,i) = filter(b,a,pm25matLog(:,i));     
    hrvmatLog30(:,i) = filter(b,a,hrvmatLog(:,i));
    
    b = (ones(timeWind(3),1) * 1/timeWind(3))';
    pm25matLog60(:,i) = filter(b,a,pm25matLog(:,i));     
    hrvmatLog60(:,i) = filter(b,a,hrvmatLog(:,i));

    b = (ones(timeWind(4),1) * 1/timeWind(4))';
    pm25matLog120(:,i) = filter(b,a,pm25matLog(:,i));     
    hrvmatLog60(:,i) = filter(b,a,hrvmatLog(:,i));
end    
format;


%% -- plotting raw data with moving averages
subplot(1,1,1) 
plot(timevec, pm25matLog(:,10), '-.', ...
     timevec, pm25matLog15(:,10), '-', ...
     timevec, pm25matLog30(:,10), '-', ...
     timevec, pm25matLog60(:,10), '-', ...
     timevec, pm25matLog120(:,10), '-'), grid on 
axis([0,T,-5,max(max(pm25matLog))])


%% 11Nov2003: Do the analysis on the LOG scale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%     IMPORTANT       %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hrvmat = hrvmatLog;

% 5-minute averages (original)
% pm25mat = pm25matLog;
% Done on 6Feb04

% 15-minute averages
%pm25mat = pm25matLog15;
% Done on 6Feb04

% 30-minute averages
% pm25mat = pm25matLog30;
% Done on 6Feb04

% 60-minute averages
% pm25mat = pm25matLog60;
% Done on 6Feb04

% 120-minute averages
% pm25mat = pm25matLog120;
% NOT DONE yet

%% Try a variation where both PM2.5 and HRV are presmoothed by moving
%% averages
% 15-minute averages
% hrvmat = hrvmatLog15;
% pm25mat = pm25matLog15;
% Done on 6Feb04

% 30-minute averages
hrvmat = hrvmatLog30;
pm25mat = pm25matLog30;
% Done on 6Feb04

%% -- plotting the data on the log-scale
subplot(2,1,1) 
plot(timevec, hrvmat) 
axis([0,T,1,6])
title('HRV')

%% -- plotting the predictor function on the log scale
subplot(2,1,2) 
plot(timevec, pm25mat) 
axis([0,T,-5,3])
title('PM2.5')

%%  --------------- set up data
tfine = (0:1:T)'; 
nfine = length(tfine); 

 hrvmatlag = zeros(nfine,N); 
 pm25matlag = zeros(nfine,N); 

for i=1:N 
    hrvtemp = interp1(timevec,hrvmat(:,i),tfine); 
    pm25temp = interp1(timevec,pm25mat(:,i),tfine); 
    hrvmatlag(:,i) = hrvtemp(1:nfine);
    pm25matlag(:,i) = pm25temp(1:nfine); 
end 


%% -- plotting the data on the log-scale
figure
subplot(2,1,1) 
plot(tfine, hrvmatlag) 
axis([0,T,1,6])
title('HRV')

%% -- plotting the predictor function on the log scale
subplot(2,1,2) 
plot(tfine, pm25matlag) 
axis([0,T,-5,3])
title('PM2.5')

%  ----------------------- Now we convert these discrete data 
%  ----------------------- to functional data objects using a B�spline basis. 

%% Trying different basis functions: in the original analysis
% B-spline basis were used
nbasis = 120; 
norder = 2; 
basis = create_bspline_basis([0,T], nbasis, norder); 
hrvfd = data2fd(hrvmatlag, tfine, basis); 
pm25fd = data2fd(pm25matlag, tfine, basis); 


% ----------    Does NOT work at the moment: 26 June 2003
% Trying polygonal basis (preserving raw data)
% basis = create_polygon_basis(tfine);
% hrvfd = data2fd(hrvmatlag, tfine, basis); 
% pm25fd = data2fd(pm25matlag, tfine, basis); 

%  ----------------  We'll also need the mean function for each variable. 
pm25meanfd = mean(pm25fd); 
hrvmeanfd = mean(hrvfd); 

%  ---------------  centered functions
hrvfd0 = center(hrvfd); 
pm25fd0 = center(pm25fd); 


%   ---------------------------------------------------------------
%   ------------------  Plotting the Bivariate Correlation Function 

%  --------------  First we define a fine mesh of time values. 
% Work
nfiney = 120;

nfinSt = nfiney + 1;
nfinEnd = 2*nfiney;

tmesh = linspace(0,T,nfiney)'; 

%   --------    get the discrete data from the functions. 
hrvfdDisc = eval_fd(hrvfd, tmesh); 
pm25fdDisc = eval_fd(pm25fd, tmesh); 

hrvfdDiscMean = mean(hrvfdDisc, 2);
pm25fdDiscMean = mean(pm25fdDisc, 2);

hrvfdDiscMed = median(hrvfdDisc, 2);
pm25fdDiscMed = median(pm25fdDisc, 2);

hrvfdDiscSD = std(hrvfdDisc, 0, 2);
pm25fdDiscSD = std(pm25fdDisc, 0, 2);

% -- plotting the mean and SD on the log-scale
subplot(2,1,1) 
plot(timevec, hrvfdDiscMean, ...
    timevec, hrvfdDiscMed, ...
    timevec, hrvfdDiscSD)
legend('Mean', 'Median', 'SD', 2)
axis([0,T,0,8])
title('Mean HRV')

% -- plotting the predictor function on the log scale
subplot(2,1,2) 
plot(timevec, pm25fdDiscMean, ...
    timevec, pm25fdDiscMed, ...
    timevec, pm25fdDiscSD) 
axis([0,T,-5,3])
title('Mean PM2.5')

%   --------- compute the correlations between the measures across curves. 
hrvpm25corr = corrcoef([hrvfdDisc',pm25fdDisc']); 
hrvpm25corr = hrvpm25corr(nfinSt:nfinEnd,1:nfiney); 
for i=2:nfiney, hrvpm25corr(i,1:i-1) = 0; end 


%  ------------- display the correlation surface
%  ----------------Use the rotation and zoom features of Matlab's 
%  -----surface display function to examine the surface from various angles. 
%  -- COLOR plotting: a) save as encapsulated color postscript file
%                     b) in GhostView use "PS printing" option
subplot(1,1,1) 
colormap(hot) 
surf(tmesh, tmesh, hrvpm25corr') 
xlabel('\fontsize{16} s') 
ylabel('\fontsize{16} t') 
axis([0,T,0,T,-1,1]) 
axis('square') 
colorbar

%  ------------------ Defining the Finite Element Basis 
%  M - number of intervals to split the time range into
%  lambda - width of the time interval
M = 30; 
% M = 120/4 
lambda = T/M; 

% --- Number of time blocks going back
B = 9; 

% -- got the functions "NodeIndexation" and "ParalleloGrid" from J. Ramsay
eleNodes = NodeIndexation(M, B); 

[Si, Ti] = ParalleloGrid(M, T, B); 

%   -- Estimating the Regression Function 
%  - The actual computation requires a discretization of the continuous 
%  - variable t. We define the spacing between these discrete values by 
%  - specifying the number of discrete values within each of the M intervals. 
%  - A value of two or four is usually sufficient to ensure a reasonably 
%  - accurate approximation. 

npts = 2; 
ntpts = M*npts; 
delta = lambda/(2*npts); 
tpts = linspace(delta, T - delta, M*npts)';

%  - Set up the design matrix that will be used in the discrete version 
%  - of the regression analysis. 
%%%%%   ------  This is a fairly length calculation. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

psiMat = DesignMatrixFD(pm25fd0, npts, M, eleNodes, Si, Ti, B); 

%  - check design matrix is NOT singular

singvals = svd(full(psiMat)); 
condition = max(singvals)/min(singvals); 
disp(['Condition number = ',num2str(condition)]) 

%  - vector of dependent variable values.  
yMat = eval_fd(hrvfd0,tpts)'; 
yVect = reshape(yMat, N*M*npts, 1);

%  - Least squares approximation that gives us our vector of regression 
%  - coefficients multiplying our basis functions. 

bHat = psiMat\yVect; 


%%%       ----------    Plotting the Regression Function 
subplot(1,1,1) 
colormap(hot) 
trisurf(eleNodes, Si, Ti, bHat) 
xlabel('\fontsize{12} s'); 
ylabel('\fontsize{12} t'); 
title(['hrv/pm25 Data Log scale (60 min)','M = ',num2str(M),', B = ',num2str(B)]) 

% - More refined plot (color): use special function BetaEvalFD. 

svec = linspace(0,T,50*4+1)'; 
tvec = linspace(0,T,50*4+1)'; 
betaMat = BetaEvalFD(svec, tvec, bHat, M, T, lambda, ... 
eleNodes, Si, Ti, B); 

subplot(1,1,1) 
colormap(hot) 
H = imagesc(tvec, tvec, betaMat); 
xlabel('\fontsize{16} s (min)') 
ylabel('\fontsize{16} t (min)') 
axis([0,T,0,T]) 
axis('square') 
Haxes = gca; 
set(Haxes,'Ydir','normal') 
title(['Coefficients b(s,t) Log scale (30 min)','M = ',num2str(M),', B = ',num2str(B)]) 
colorbar

%%%%    -------  Computing the Fit to the Data 
%  - Set up a large super�matrix containing the approximated hrv 
%  - using the special function XMatrix. 
%%%         --- This is also a lengthy calculation. 

psiArray = XMatrix(pm25fd, tmesh, M, eleNodes, Si, Ti, B); 

%  - Matrix of approximation values for the hrv acceleration curves 

yHat1 = zeros(nfiney,N); 

for i=1:N 
Xmati = squeeze(psiArray(i,:,:))'; 
yHat1(:,i) = Xmati*bHat; 
end 

%  - Approximation is based only on the estimated regression function b(s,t). 
%  - To complete the approximation, we must get the intercept function a(t). 
%  - This requires using the mean pm25 curve as a model, and subtracting 
%  - the fit that this gives from the mean hrv acceleration. 

psimeanArray = XMatrix(pm25meanfd, tmesh, M, eleNodes, Si, Ti, B); 
yHatMean = squeeze(psimeanArray)'*bHat; 
hrvmeanvec = eval_fd(hrvmeanfd, tmesh); 
alphaHat = hrvmeanvec - yHatMean; 

%  - Plot the intercept function. 
subplot(2,1,1)
plot(tmesh,alphaHat) 
title('Estimated intercept function'); 

%  - Plot the fit at the mean pm25 concentrations
subplot(2,1,2)
plot(tmesh,yHatMean) 
title('Estimated predictions at the mean PM2.5 concentrations'); 

%  - Final fit to the data. 
yHat = alphaHat*ones(1,N) + yHat1; 

%  - Plot the data and the fit to the data. 
subplot(2,1,1) 
plot(tmesh, yHat) 
axis([0,T,0,6]) 
title('Fit to the data')
subplot(2,1,2) 
plot(tmesh, hrvfdDisc) 
axis([0,T,0,6])
title('Original data')

%  - Plot the residuals. 
subplot(1,1,1) 
resmat = hrvfdDisc - yHat; 
plot(tmesh, resmat) 
axis([0,T,-2,2]) 


%%%%%       ----- Assessing the Fit 
%  - Error sum of squares function. 
SSE = sum(resmat.^2,2); 

%  - Benchmark against which we can assess this fit, we need to get the 
%  - corresponding error sum of squares function when the model is simply 
%  - the mean hrv acceleration curve. 

hrvmat0 = eval_fd(hrvfd0, tmesh); 
SSY = sum(hrvmat0.^2,2); 

%  - compute a squared multiple correlation function and plot it. 
%  - Don't be suprised, though, to see it go below zero; 
%  - the fit from the mean is not embedded within the fit by the model. 
RSQ = (SSY - SSE)./SSY; 
subplot(1,1,1) 
plot(tmesh,RSQ); 
axis([0,T,-0.7,1]) 

