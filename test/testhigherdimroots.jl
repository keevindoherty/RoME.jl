using RoME, IncrementalInference, TransformUtils, Distributions
using Base.Test
# import  IncrementalInference: getSample


mutable struct RotationTest <: IncrementalInference.FunctorPairwise
  z::MvNormal
end

# 3 dimensional line, z = [a b][x y]' + c
function (rt::RotationTest)(res::Vector{Float64}, userdata, idx, meas, var1, var2)
  z = view(meas[1],:,idx)
  dq = convert(Quaternion, Euler(z...))
  s1 = so3(var1[:,idx])
  s2 = so3(var2[:,idx])
  q1 = convert(Quaternion, s1)
  q2 = convert(Quaternion, s2)
  q12 = q1*q_conj(q2)
  qq = dq*q_conj(q12)
  vee!(res, convert(so3, qq))
  nothing
end

rr = RotationTest(MvNormal(zeros(3), 0.001*eye(3)))



@testset "Increased dimension root finding test" begin

# known rotations
eul = zeros(3,1)

R1 = zeros(3,1)
R2 = zeros(3,1)

res = randn(3)

rr(res, nothing, 1, (zeros(3,1),), R1, R2)
@test norm(res) < 1e-10



# random rotations
eul = 0.25*randn(3, 1)

R1 = rand(3,1)
R2 = rand(3,1)

res = zeros(3)

rr(res, nothing, 1, (zeros(3),), R1, R2)

@test norm(res) > 1e-3


end


@testset "test FastRootGenericWrapParam functions" begin


N = 10

for i in 1:5


eul = 0.25*randn(3, N)
# res = zeros(3)
# @show rotationresidual!(res, eul, (zeros(0),x0))
# @show res
# gg = (res, x) -> rotationresidual!(res, eul, (zeros(0),x))
x0 = 0.1*randn(3)
res = zeros(3)
# @show gg(res, x0)
# @show res

A = rand(3,N)
B = rand(3,N)
At = deepcopy(A)
t = Array{Array{Float64,2},1}()
push!(t,A)
push!(t,B)
rr = RotationTest(MvNormal(zeros(3), 0.001*eye(3)))

gwp = GenericWrapParam{RotationTest}(rr, t, 1, 1)

@time gwp(res, x0)

# gwp.activehypo
# gwp.hypotheses
# gwp.params

# @show gwp.varidx
gwp.measurement = (eul, )
zDim = 3
fr = FastRootGenericWrapParam{RotationTest}(gwp.params[gwp.varidx], zDim, gwp)

@test fr.xDim == 3

# and return complete fr/gwp
for gwp.particleidx in 1:N
# gwp(x, res)
numericRootGenericRandomizedFnc!( fr )

# test the result
qq = convert(Quaternion, Euler(eul[:,gwp.particleidx]...))
q1 = convert(Quaternion, so3(fr.Y))
q2 = convert(Quaternion, so3(B[:,gwp.particleidx]))
@test TransformUtils.compare(q1*q_conj(q2), qq, tol=1e-8)


end # particle for

end # i for

end # testset
