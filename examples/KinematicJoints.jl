
using Caesar
using RoME, Distributions
import IncrementalInference: getSample

using TransformUtils


type HipJoint <: FunctorPairwise
  Zij::Distribution
end
function getSample(el::HipJoint, N=1)
  return (rand(el.Zij, N),)
end
function (el::HipJoint)(res, idx, meas, xi, xj)
  Xi = SE3(xi[1:3,idx],Euler(xi[4:6,idx]))
  Xj = SE3(xj[1:3,idx],Euler(xj[4:6,idx]))

  h=meas[1][idx]
  # hip = SE3([0,0,0.5], Euler(0,0,h))
  # delta = (Xi ⊕ hip)\Xj # TODO -- THERE IS SOME MAJORLY SILLY ISSUE HERE

  # res[1:6] = veeEuler(delta)

  res[1:3] = (xi[1:3,idx] + [0,0,0.5]) - xj[1:3,idx] # cheating with 0.5 before rotation
  res[4:5] = xi[4:5,idx] - xj[4:5,idx]
  res[6] = wrapRad(wrapRad(xi[6,idx] + meas[1][idx]) - xj[6,idx])
  nothing
end




N=100
fg = RoME.initfg()

# base
addNode!(fg, :x1, dims=6)
pos = PriorPose3(MvNormal(zeros(6),1e-6*eye(6)))
addFactor!(fg, [:x1], pos) # base
initializeNode!(fg, :x1)


# torso
addNode!(fg, :x2, dims=6)
hip = HipJoint(Normal(pi/3,0.1))
addFactor!(fg, [:x1, :x2], hip) # hio
initializeNode!(fg, :x2)




# using IncrementalInference
#
# pts = evalFactor2(fg, fg.g.vertices[fg.fIDs[:x1x2]], fg.IDs[:x2])
#
# @show Base.mean(pts,2)



# setup visualization process and default drawings
vis = startdefaultvisualization()


visualizeallposes!(vis, fg, drawtype=:max)



solveandvisualize(fg, vis)


Graphs.plot(fg.g)

visualizeDensityMesh!(vis, fg, :x2)

plotKDE(fg, :x2, dims=[4])

plotPose3Pairs(fg, :x2)







type ShoulderJoint <: FunctorPairwise
  Zij::Distribution
end
function getSample(el::ShoulderJoint, N=1)
  return (rand(el.Zij, N),)
end
function (el::ShoulderJoint)(res, idx, meas, xi, xj)
  Xi = SE3(xi[1:3,idx],Euler(xi[4:6,idx]))
  Xj = SE3(xj[1:3,idx],Euler(xj[4:6,idx]))

  sho1 = SE3( zeros(3), convert(SO3,so3([meas[1][idx],0,0])) )
  sho2 = SE3( [0,0,1.0], SO3(0) )

  del = (Xi ⊕ sho1 ⊕ sho2) \ Xj

  res[1:6] = veeEuler(del)
  nothing
end








# torso
addNode!(fg, :x3, dims=6)
should = ShoulderJoint(Normal(pi/4,0.1))
addFactor!(fg, [:x2, :x3], should) # hio
initializeNode!(fg, :x3)






visualizeallposes!(vis, fg, drawtype=:max)



solveandvisualize(fg, vis)











# reachability Examples


N=300
fg = RoME.initfg()

# base
addNode!(fg, :x1, dims=6)
pos = PriorPose3(MvNormal(zeros(6),1e-6*eye(6)))
addFactor!(fg, [:x1], pos) # base
initializeNode!(fg, :x1)


addNode!(fg, :x2, dims=6)
hip = HipJoint(Uniform(-pi/3,pi/3))
addFactor!(fg, [:x1, :x2], hip) # hio
initializeNode!(fg, :x2)


addNode!(fg, :x3, dims=6)
should = ShoulderJoint(Uniform(-pi/4,pi/4))
addFactor!(fg, [:x2, :x3], should) # hio
initializeNode!(fg, :x3)


visualizeallposes!(vis, fg, drawtype=:max)


solveandvisualize(fg, vis)



visualizeDensityMesh!(vis, fg, :x3)


plotPose3Pairs(fg, :x3)

getVal(fg, :x3)[5,1:10]

plotKDE(fg, :x3, dims=[6])




rand(Uniform(-1,1))













#