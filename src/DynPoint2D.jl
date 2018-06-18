# 2D SLAM with velocity states


# x, y, dx/dt, dy/dt
mutable struct DynPoint2 <: IncrementalInference.InferenceVariable
  ut::Int64 # microsecond time
  dims::Int
  labels::Vector{String}
  DynPoint2(;ut::Int64=0, labels::Vector{<:AbstractString}=String[]) = new(ut, 4, labels)
end


mutable struct DynPoint2VelocityPrior{T} <: IncrementalInference.FunctorSingleton where {T <: Distribution}
  z::T
  DynPoint2VelocityPrior{T}() where {T <: Distribution} = new{T}()
  DynPoint2VelocityPrior(z1::T) where {T <: Distribution} = new{T}(z1)
end
getSample(dp2v::DynPoint2VelocityPrior, N::Int=1) = (rand(dp2v.z,N), )


mutable struct DynPoint2DynPoint2{T} <: IncrementalInference.FunctorPairwise where {T <: Distribution}
  z::T
  DynPoint2DynPoint2{T}() where {T <: Distribution} = new{T}()
  DynPoint2DynPoint2(z1::T) where {T <: Distribution} = new{T}(z1)
end
getSample(dp2dp2::DynPoint2DynPoint2, N::Int=1) = (rand(dp2dp2.z,N), )
function (dp2dp2::DynPoint2DynPoint2)(
            res::Array{Float64},
            userdata,
            idx::Int,
            meas::Tuple,
            Xi::Array{Float64,2},
            Xj::Array{Float64,2}  )
  #
  z = meas[1][:,idx]
  xi, xj = Xi[:,idx], Xj[:,idx]
  dt = (userdata.variableuserdata[2].ut - userdata.variableuserdata[1].ut)*1e-6   # roughly the intended use of userdata
  res[1:2] = z[1:2] - (xj[1:2] - (xi[1:2]+dt*xi[3:4]))
  res[3:4] = z[3:4] - (xj[3:4] - xi[3:4])
  nothing
end
function (dp2dp2::DynPoint2DynPoint2)(res::Array{Float64},
            idx::Int,
            meas::Tuple,
            Xi::Array{Float64,2},
            Xj::Array{Float64,2}  )
  #
  error("function (dp2dp2::DynPoint2DynPoint2) requires newer version of IncrementalInference that passes user data to the residual function.")
end


mutable struct VelPoint2VelPoint2{T} <: IncrementalInference.FunctorPairwiseMinimize where {T <: Distribution}
  z::T
  VelPoint2VelPoint2{T}() where {T <: Distribution} = new{T}()
  VelPoint2VelPoint2(z1::T) where {T <: Distribution} = new{T}(z1)
end
getSample(vp2vp2::VelPoint2VelPoint2, N::Int=1) = (rand(vp2vp2.z,N), )
function (vp2vp2::VelPoint2VelPoint2)(
                res::Array{Float64},
                userdata,
                idx::Int,
                meas::Tuple,
                Xi::Array{Float64,2},
                Xj::Array{Float64,2}  )
  #
  z = meas[1][:,idx]
  xi, xj = Xi[:,idx], Xj[:,idx]
  dt = (userdata.variableuserdata[2].ut - userdata.variableuserdata[1].ut)*1e-6   # roughly the intended use of userdata
  dp = (xj[1:2]-xi[1:2])
  dv = (xj[3:4]-xi[3:4])
  res[1] = 0.0
  res[1] += sum((z[1:2] - dp).^2)
  res[1] += sum((z[3:4] - dv).^2)
  res[1] += sum((dp/dt - xi[3:4]).^2)  # (dp/dt - 0.5*(xj[3:4]+xi[3:4])) # midpoint integration
  res[1]
end
function (vp2vp2::VelPoint2VelPoint2)(
                res::Array{Float64},
                idx::Int,
                meas::Tuple,
                Xi::Array{Float64,2},
                Xj::Array{Float64,2}  )
  #
    error("function (vp2vp2::VelPoint2VelPoint2) requires newer version of IncrementalInference that passes user data to the residual function.")
end



mutable struct Point2Point2Velocity{T} <: IncrementalInference.FunctorPairwiseMinimize where {T <: Distribution}
  z::T
  Point2Point2Velocity{T}() where {T <: Distribution} = new{T}()
  Point2Point2Velocity(z1::T) where {T <: Distribution} = new{T}(z1)
end
getSample(p2p2v::Point2Point2Velocity, N::Int=1) = (rand(p2p2v.z,N), )
function (p2p2v::Point2Point2Velocity)(
                res::Array{Float64},
                userdata,
                idx::Int,
                meas::Tuple,
                Xi::Array{Float64,2},
                Xj::Array{Float64,2}  )
  #
  z = meas[1][:,idx]
  xi, xj = Xi[:,idx], Xj[:,idx]
  dt = (userdata.variableuserdata[2].ut - userdata.variableuserdata[1].ut)*1e-6   # roughly the intended use of userdata
  dp = (xj[1:2]-xi[1:2])
  dv = (xj[3:4]-xi[3:4])
  res[1] = 0.0
  res[1] += sum((z[1:2] - dp).^2)
  res[1] += sum((dp/dt - 0.5*(xj[3:4]+xi[3:4])).^2)  # (dp/dt - 0.5*(xj[3:4]+xi[3:4])) # midpoint integration
  res[1]
end
function (p2p2v::Point2Point2Velocity)(
                res::Array{Float64},
                idx::Int,
                meas::Tuple,
                Xi::Array{Float64,2},
                Xj::Array{Float64,2}  )
  #
    error("function (vp2vp2::VelPoint2VelPoint2) requires newer version of IncrementalInference that passes user data to the residual function.")
end