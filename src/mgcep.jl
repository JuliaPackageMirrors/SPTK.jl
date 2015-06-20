# Mel-generalized cepstrum analysis

function mcep!(mc::Vector{Cdouble}, windowed::Vector{Cdouble}, α=0.41;
               miniter::Int=2,
               maxiter::Int=30,
               threshold::Float64=0.001,
               etype::Int=0,
               eps::Float64=0.0,
               min_det::Float64=1.0e-6,
               itype::Int=0)
    if itype ∉ 0:4
        throw(ArgumentError("unsupported itype: $itype, must be ∈ 0:4"))
    end
    if etype ∉ 0:2
        throw(ArgumentError("unsupported etype: $etype, must be ∈ 0:2"))
    end
    if etype == 0 && eps != 0.0
        throw(ArgumentError("eps cannot be specified for etype = 0"))
    end
    if etype ∈ 1:2 && eps < 0.0
        throw(ArgumentError("eps: $eps, must be >= 0"))
    end
    if min_det < 0.0
       throw(ArgumentError("min_det must be positive: min_det = $min_det"))
    end

    order = length(mc) - 1
    ccall((:mcep, libSPTK), Cint,
          (Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint,
           Cdouble, Cint, Cint, Cdouble, Cint, Cdouble, Cdouble, Cint),
          windowed, length(windowed), mc, order, α,
          miniter, maxiter, threshold, etype, eps, min_det, itype)
    mc
end

function mcep(windowed::Vector{Cdouble}, order=40, α=0.41; kargs...)
    mc = zeros(order+1)
    mcep!(mc, windowed, α; kargs...)
end

function gcep!(gc::Vector{Cdouble}, windowed::Vector{Cdouble}, γ=0.0;
               miniter::Int=2,
               maxiter::Int=30,
               threshold::Float64=0.001,
               etype::Int=0,
               eps::Float64=0.0,
               min_det::Float64=0.000001,
               itype::Int=0)
    if !(-1 <= γ <= 0.0)
        throw(ArgumentError("unsupported γ: must be -1 <= γ <= 0)"))
    end
    if itype ∉ 0:4
        throw(ArgumentError("unsupported itype: $itype, must be ∈ 0:4"))
    end
    if etype ∉ 0:2
        throw(ArgumentError("unsupported etype: $etype, must be ∈ 0:2"))
    end
    if etype == 0 && eps != 0.0
        throw(ArgumentError("eps cannot be specified for etype = 0"))
    end
    if etype ∈ 1:2 && eps < 0.0
        throw(ArgumentError("eps: $eps, must be >= 0"))
    end
    if min_det < 0.0
       throw(ArgumentError("min_det must be positive: min_det = $min_det"))
    end

    order = length(gc) - 1
    ccall((:gcep, libSPTK), Cint,
          (Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint,
           Cdouble, Cint, Cint, Cdouble, Cint, Cdouble, Cdouble, Cint),
          windowed, length(windowed), gc, order, γ,
          miniter, maxiter, threshold, etype, eps, min_det, itype)
    gc
end

function gcep(windowed::Vector{Cdouble}, order=40, γ=0.0; kargs...)
    gc = zeros(order + 1)
    gcep!(gc, windowed, γ; kargs...)
end

function mgcep!(mgc::Vector{Cdouble}, windowed::Vector{Cdouble}, α=0.41,
                γ=0.0;
                num_recursions::Int=length(windowed)-1,
                miniter::Int=2,
                maxiter::Int=30,
                threshold::Float64=0.001,
                etype::Int=0,
                eps::Float64=0.0,
                min_det::Float64=0.0001,
                itype::Int=0,
                otype::Int=0)
    if !(-1 <= γ <= 0.0)
        throw(ArgumentError("unsupported γ: must be -1 <= γ <= 0)"))
    end
    if itype ∉ 0:4
        throw(ArgumentError("unsupported itype: $itype, must be ∈ 0:4"))
    end
    if etype ∉ 0:2
        throw(ArgumentError("unsupported etype: $etype, must be ∈ 0:2"))
    end
    if etype == 0 && eps != 0.0
        throw(ArgumentError("eps cannot be specified for etype = 0"))
    end
    if etype ∈ 1:2 && eps < 0.0
        throw(ArgumentError("eps: $eps, must be >= 0"))
    end
    if min_det < 0.0
       throw(ArgumentError("min_det must be positive: min_det = $min_det"))
    end
    if otype ∉ 0:5
        throw(ArgumentError("unsupported otype: $otype, must be ∈ 0:5"))
    end

    order = length(mgc) - 1
    ccall((:mgcep, libSPTK), Cint,
          (Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint, Cdouble, Cdouble,
           Cint, Cint, Cint, Cdouble, Cint, Cdouble, Cdouble, Cint),
          windowed, length(windowed), mgc, order, α, γ, num_recursions,
          miniter, maxiter, threshold, etype, eps, min_det, itype)

    if otype == 0 || otype == 1 || otype == 2 || otype == 4
        ccall((:ignorm, libSPTK), Void, (Ptr{Cdouble}, Ptr{Cdouble},
                                           Cint, Cdouble),
              mgc, mgc, order, γ)
    end

    if otype == 0 || otype == 2 || otype == 4
        ccall((:b2mc, libSPTK), Void,
              (Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cdouble),
              mgc, mgc, order, α)
    end

    if otype == 2 || otype == 4
        ccall((:gnorm, libSPTK), Void, (Ptr{Cdouble}, Ptr{Cdouble},
                                          Cint, Cdouble),
              mgc, mgc, order, γ)
    end

    if otype == 4 || otype == 5
        mgc = [mgc[1], mgc[2:end]*γ]
    end

    mgc
end

function mgcep(windowed::Vector{Cdouble}, order=40, α=0.41, γ=0.0; kargs...)
    mgc = zeros(order + 1)
    mgcep!(mgc, windowed, α, γ; kargs...)
end

function uels!(c::Vector{Cdouble}, windowed::Vector{Cdouble};
               miniter::Int=2,
               maxiter::Int=30,
               threshold::Float64=0.001,
               etype::Int=0,
               eps::Float64=0.0,
               itype::Int=0)
    if itype ∉ 0:4
        throw(ArgumentError("unsupported itype: $itype, must be ∈ 0:4"))
    end
    if etype ∉ 0:2
        throw(ArgumentError("unsupported etype: $etype, must be ∈ 0:2"))
    end
    if etype == 0 && eps != 0.0
        throw(ArgumentError("eps cannot be specified for etype = 0"))
    end
    if etype ∈ 1:2 && eps < 0.0
        throw(ArgumentError("eps: $eps, must be >= 0"))
    end

    order = length(c) - 1
    ccall((:uels, libSPTK), Cint,
          (Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint, Cint, Cint, Cdouble, Cint,
           Cdouble, Cint),
          windowed, length(windowed), c, order,
          miniter, maxiter, threshold, etype, eps, itype)
    c
end

function uels(windowed::Vector{Cdouble}, order=40; kargs...)
    c = zeros(order + 1)
    uels!(c, windowed; kargs...)
end

function fftcep!(c::Vector{Cdouble}, logsp::Vector{Cdouble};
                 num_iter::Int=0,
                 acceleration_factor::Float64=0.0)
    order = length(c) - 1
    ccall((:fftcep, libSPTK), Void,
          (Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint, Cint, Cdouble),
          logsp, length(logsp), c, length(c), num_iter, acceleration_factor)
    c
end

function fftcep(logsp::Vector{Cdouble}, order=40; kargs...)
    c = zeros(order + 1)
    fftcep!(c, logsp; kargs...)
end

function lpc!(a::Vector{Cdouble}, x::Vector{Cdouble};
             min_det::Float64=1.0e-6)
    if min_det < 0.0
       throw(ArgumentError("min_det must be positive: min_det = $min_det"))
    end

    order = length(a) - 1
    ccall((:lpc, libSPTK), Void,
          (Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint, Cdouble),
          x, length(x), a, order, min_det)
    a
end

function lpc(x::Vector{Cdouble}, order=40; kargs...)
    a = Array(Cdouble, order+1)
    lpc!(a, x; kargs...)
end