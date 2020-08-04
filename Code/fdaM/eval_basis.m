function evalarray = eval_basis(evalarg, basisobj, Lfdobj)
%  EVAL_BASIS evaluates a basis at argument values EVALARG.
%
%  LFDOBJ is a functional data object defining the order m 
%  NONHOMOGENEOUS linear differential operator of the form
%  Lx(t) = w_0(t) x(t) + w_1(t) Dx(t) + ... 
%          w_{m-1}(t) D^{m-1}x(t) + D^m x(t) + ...
%          a_1(t) u_1(t)  + ... + a_k(t) u_k(t).
%  This is a change from previous usage where LFDOBJ was assumed to 
%  define a HOMOGONEOUS differential operator.  See function
%  @Lfd/Lfd() for details.
%
%  Arguments:
%  EVALARG ... A vector of values at which all functions are to 
%              evaluated.
%  BASISOBJ ... A basis object
%  LFDOBJ   ... A linear differential operator object
%              applied to the functions that are evaluated.
%
%  Note that the first two arguments may be interchanged.
%
%  Returns:  An array of function values corresponding to the evaluation
%              arguments in EVALARG

%  Last modified 30 January 2003

if nargin < 2
    error('Number of arguments is less than 2.');
end

%  set default LFDOBJ to 0

if nargin < 3     
    Lfdobj = int2Lfd(0); 
end

%  check LFDOBJ

Lfdobj = int2Lfd(Lfdobj);

%  Exchange the first two arguments if the first is a BASIS
%    and the second numeric

if isnumeric(basisobj) & isa_basis(evalarg)
    temp     = basisobj;
    basisobj = evalarg;
    evalarg  = temp;
end

%  check EVALARG

sizeevalarg = size(evalarg);
if sizeevalarg(1) > 1 & sizeevalarg(2) > 1
    error('Argument EVALARG is not a vector.');
end
evalarg = evalarg(:);

%  check BASISOBJ

if ~isa_basis(basisobj)
    error ('Argument BASISOBJ is not a basis object.');
end

%  check LFDOBJ

if ~isa_Lfd(Lfdobj)
    error ('LFD is not a linear differential operator object.');
end

%  get basis information

nbasis = getnbasis(basisobj);
onerow = ones(1,nbasis);

%  determine the highest order of derivative NDERIV required

nderiv = getnderiv(Lfdobj);

%  get highest order of basis matrix

evalarray = getbasismatrix(evalarg, basisobj, nderiv);

%  Compute the weighted combination of derivatives is 
%  evaluated here if the operator is not defined by an 
%  integer and the order of derivative is positive.
%  Only the homogeneous part of the operator, defined by
%  cell object WFDCELL is used.

if nderiv > 0 & ~isinteger(Lfdobj)
    wfdcell = getwfd(Lfdobj);
    %  In this version, only a scalar operator is allowed.
    if size(wfdcell,1) ~= 1
        error('WFDCELL has more than one row.');
    end
    for j = 1:nderiv
        wcoef = getcoef(wfdcell{j});
        if ~all(all(wcoef)) == 0.0
            wmat  = eval_fd(evalarg, wfdcell{j});
            evalarray = evalarray + (wmat*onerow).* ...
                getbasismatrix(evalarg, basisobj, j-1);
        end
    end
end

