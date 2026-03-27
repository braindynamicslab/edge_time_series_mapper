function mod = fcn_BCT_calMod(W, m0)
    s = sum(sum(W));
    gamma = 1;
    B = (W-gamma*(sum(W,2)*sum(W,1))/s)/s;
    B = (B+B.')/2;
    mod = sum(B(bsxfun(@eq, m0, m0')));
end