abstract WaveformGenerationFilter

# MLSADF represents a Mel Log Spectrum Approximation (MLSA) digtal filter
type MLSADF <: WaveformGenerationFilter
    order::Int              # order of mel-cepstrum
    pd::Int                 # order of pade approximation
    delay::Vector{Float64}  # filter delay
end

# see mlsadf.c in the original SPTK for this magic allocation
mlsadf_delay(order::Int, pd::Int) = zeros(3*(pd+1)+pd*(order+2))

MLSADF(order::Int; pd::Int=5) = MLSADF(order, pd, mlsadf_delay(order, pd))

# Note that filter! will modify MLSADF delay.
function filter!(m::MLSADF, x::Real, b::Vector{Float64}, alpha::Float64)
    const order = length(b) - 1
    order == m.order ||
        throw(DimensionMismatch("Order of mel-cepstrum may be wrong."))

    return mlsadf(float64(x), b, alpha, m.pd, m.delay)
end

# MGLSADF represents a Mel Generalized Log Spectrum Approximation (MGLSA)
# digital filter.
type MGLSADF <: WaveformGenerationFilter
    order::Int
    stage::Int
    delay::Vector{Float64}
end

# see mglsadf.c in the original SPTK for this magic allocation
mglsadf_delay(order::Int, stage::Int) = zeros((order+1)*stage)

MGLSADF(order::Int, stage::Int) =
    MGLSADF(order, stage, mglsadf_delay(order, stage))

function filter!(m::MGLSADF, x::Real, b::Vector{Float64}, alpha::Float64)
    const order = length(b) - 1
    order == m.order ||
        throw(DimensionMismatch("Order of mel generalized cepstrum may be wrong."))

    return mglsadf(float64(x), b, alpha, m.stage, m.delay)
end

# synthesis_one_frame! generates speech waveform for one frame speech signal
# given a excitation signal and successive two mel generalized cepstrum.
function synthesis_one_frame!(f::WaveformGenerationFilter,
                              excite::Vector{Float64},
                              previous_mgc::Vector{Float64},
                              current_mgc::Vector{Float64},
                              alpha::Float64,
                              gamma::Float64)
    previous_coef = mgc2b(previous_mgc, alpha, gamma)
    current_coef = mgc2b(current_mgc, alpha, gamma)

    slope = (current_coef - previous_coef) / float(length(excite))

    part_of_speech = Array(eltype(excite), length(excite))
    interpolated_coef = copy(previous_coef)

    for i=1:endof(excite)
        scaled_excitation = excite[i] * exp(interpolated_coef[1])
        part_of_speech[i] = filter!(f, scaled_excitation,
                                    interpolated_coef, alpha)
        interpolated_coef += slope
    end

    return part_of_speech
end

# Special case
synthesis_one_frame!(f::MLSADF, excite, previous_mgc, current_mgc, alpha) =
    synthesis_one_frame!(f, excite, previous_mgc, current_mgc, alpha, 0.0)

# synthesis! generates a speech waveform given a excitation signal and
# a sequence of mel generalized cepstrum.
function synthesis!(f::WaveformGenerationFilter,
                    excite::Vector{Float64},
                    mgc_sequence::Matrix{Float64},
                    alpha::Float64,
                    hopsize::Int,
                    gamma::Float64)
    const T = length(excite)
    synthesized = zeros(T)

    previous_mgc = mgc_sequence[:,1]
    for i=1:size(mgc_sequence, 2)
        if i > 1
            previous_mgc = mgc_sequence[:,i-1]
        end
        current_mgc = mgc_sequence[:,i]

        const s, e = (i-1)*hopsize+1, i*hopsize
        if e > T
            break
        end

        part_of_speech = synthesis_one_frame!(f, excite[s:e],
                                              previous_mgc,
                                              current_mgc, alpha, gamma)
        synthesized[s:e] = part_of_speech
    end

    return synthesized
end

# Special case
synthesis!(f::MLSADF, excite, mgc_sequence, alpha, hopsize) =
    synthesis!(f, excite, mgc_sequence, alpha, hopsize, 0.0)