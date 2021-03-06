
%{
	Gravitational N-body simulation in MATLAB
	Main program

	Author(s):
		Jarl Gullberg (199706013175) <jarl.gullberg@gmail.com>
		Karl Brorsson (199406189036) <brorssonkarl@gmail.com>
		Alexander Johansson (199701114499) <alexander.johansson97@hotmail.se>

	Due to constraints, the main loop has been placed in the 
	class declaration as a static function. In order to run the 
	simulation, run the following static function without parameters:

	GravitationalBody.Simulate()

    Any required parameters will be collected from the user. 


	A simpler simulation with standard values can be started using the 
	following static function:

	GravitationalBody.SimulateSimple(bodyCount)


	A parameterized static function is also available for use within
	other code, in the following format:
	
	GravitationalBody.SimulateParameterized(bodyCount, minMaxX, minMaxY, minMaxR, withGreatAttractor, timeStep)


    Due to a number of factors, the simulation may take a very long time to
    complete - objects are commonly slingshotted away from the visible
    screen by gravitational forces, but remain in the simulation for
    correctness. These objects will - eventually - coalesce into a single
    point, but it may not be visible in the end. Therefore, a "great
    attractor" can be generated in the center of the visible area, which
    acts as a fixed point in the simulation. One can think of this as a sun
    or planet surrounded by asteroids, which the simulation follows.
%}

classdef GravitationalBody < handle
	%GravitationalBody A structure representing a gravitational body.
	%   This class contains all data and methods required to
	%	hold and compute relational gravity data.
	
	properties	
		IsAlive = true;
		
		% Positional data as a 2-element vector
		XY = [0, 0]
		
		% Mass
		Radius = 1
		
		% The colour of the mass as an RGB triplet
		RGB = [1, 1, 1]
		
		% Forces
		VelocityVector = [0, 0]
		AccelerationVector = [0, 0]
		
		% The graphical object on the simulation axes
		GraphicalObject
		
		% Whether or not this body is a fixed point in the simulation
		IsFixedPoint
	end
	
	methods (Static)
		function body = CreateRandomBody(minMaxX, minMaxY, minMaxR)
			% CREATERANDOMBODY Creates a random gravitational body,
			% constrained to the parameters provided.
			%
			% PARAM minMaxX The starting range of the X position of the body 
			% (as a 2-element vector).
			% PARAM minMaxY The starting range of the Y position of the body
			% (as a 2-element vector).
			% PARAM minMaxR The minimum and maximum radius of the body
			% (as a 2-element vector).
			
			% Check the input variables
			if (numel(minMaxX) ~= 2)
				fprintf('The parameter "minXY" must be a 2-element vector.');
			end
			
			if (numel(minMaxY) ~= 2)
				fprintf('The parameter "maxXY" must be a 2-element vector.');
			end
			
			if (numel(minMaxR) ~= 2)
				fprintf('The parameter "minMaxR" must be a 2-element vector.');
			end
			
					
			% Create two random X and Y values
			randX = minMaxX(1) + (minMaxX(2) - minMaxX(1)).*rand(1,1);
			randY = minMaxY(1) + (minMaxY(2) - minMaxY(1)).*rand(1,1);
						
			% Create a random radius
			randR = (minMaxR(2) - minMaxR(1)).*rand(1,1) + minMaxR(1);
						
			% Create a random colour
			randColour = rand(1, 3);
				
			% Initialize a new body
			body = GravitationalBody([randX, randY], randR, randColour, false);
        end
        
        function result = lerp(v0, v1, t)
            result = (1-t)*v0+t*v1;  
		end
		
		function SimulateSimple(bodyCount)
			% SIMULATESIMPLE(bodyCount) Starts a simple simulation with the
			% specified number of bodies.
			%
			% This function starts a simple simulation with the specified 
			% number of bodies using a set of standard settings (a surface
			% of 1000x1000, min/max radii of 2 and 8 and a timestep of 120)
			%
			% PARAM bodyCount An unsigned integer, specifying the number of
			% bodies to create in the simulation.
			
			
			minMaxX = [0, 1000];
			minMaxY = [0, 1000];
			minMaxR = [2, 8];

			withGreatAttractor = false;

			timeStep = 120;

			rng('shuffle');
			GravitationalBody.SimulateParameterized(bodyCount, minMaxX, minMaxY, minMaxR, withGreatAttractor, timeStep);
		end
		
		function SimulateParameterized(bodyCount, minMaxX, minMaxY, minMaxR, withGreatAttractor, timeStep)
			% Setup - time delta
			lastFrameTime = 5;

			% Setup - rendering
			clf('reset');
			graphAxes = axes('PlotBoxAspectRatio', [1, 1, 1]);
			axis(graphAxes, [minMaxX, minMaxY]);
			grid(graphAxes, 'on');

			% Setup - body generation, no attractor
			if (withGreatAttractor)
				gravitationalBodies = GravitationalBody.empty(bodyCount + 1, 0);
				for i = 1 : bodyCount
					gravitationalBodies(i) = GravitationalBody.CreateRandomBody(minMaxX, minMaxY, minMaxR);
				end

				gravitationalBodies(bodyCount + 1) = GravitationalBody([minMaxX(2) / 2, minMaxY(2) / 2], minMaxR(2) * 2, [1, 1, 0], true);
			else
				gravitationalBodies = GravitationalBody.empty(bodyCount, 0);
				for i = 1 : bodyCount
					gravitationalBodies(i) = GravitationalBody.CreateRandomBody(minMaxX, minMaxY, minMaxR);
				end
			end


			% Run simulation

			while (size(gravitationalBodies,  2) > 1)
				% Run one frame of the simulation and store the time taken to 
				% perform that simulation (in milliseconds).
				[lastFrameTime, gravitationalBodies] = GravitationalBody.RunFrame(gravitationalBodies, lastFrameTime, timeStep, graphAxes);
				lastFrameTime = lastFrameTime * 1000;
			end
		end
		
		function Simulate()
			bodyCount = 0;
			minMaxX = [0 0];
			minMaxY = [0 0];
			minMaxR = [0 0];
			withGreatAttractor = false;
			timeStep = 0;

			% Setup - simulation parameters
			isDebug = false;
			if (isDebug)
				bodyCount = 100;
				minMaxX = [0, 1000];
				minMaxY = [0, 1000];
				minMaxR = [2, 8];

				withGreatAttractor = false;

				timeStep = 120;

				rng('shuffle');
			else
				bodyCount = input('Enter the desired number of simulated bodies: \n$: ');
				minMaxX = input('Enter the minimum and maxiumum X values as a vector in the format [XMin, XMax] \n$: ');
				minMaxY = input('Enter the minimum and maxiumum Y values as a vector in the format [YMin, YMax] \n$: ');
				minMaxR = input('Enter the minimum and maximum initial radii values of the bodies as a vector in the format [RMin, RMax] \n$: ');
				withGreatAttractorInput = input('Should a fixed point be included in the simulation? \n(Effectively, this will follow a large body in a field of other smaller bodies) [y/n] \n$: ', 's');

				if (lower(withGreatAttractorInput) == 'y')
					withGreatAttractor = true;
				end


				timeStep = input('Enter the desired time step of the simulation (in milliseconds): \n$: ');

				%rng(input('Enter a non-negative seed value for the random number generator: \n'), 'simdTwister')
				rng('shuffle');

				input('Parameters loaded. Press enter to begin.');
			end
			
			GravitationalBody.SimulateParameterized(bodyCount, minMaxX, minMaxY, minMaxR, withGreatAttractor, timeStep)
		end

		function [timeTaken, remainingBodies] = RunFrame(gravitationalBodies, deltaTime, seconds, graphAxes)
			tic

			remainingBodies = gravitationalBodies;

			% Dump the dead bodies from last frame
			deadIndices = [];
			for i = 1 : size(remainingBodies, 2)
				gravitationalBody = remainingBodies(i);
				if (~gravitationalBody.IsAlive)
					deadIndices = [deadIndices, i];
				end
			end

			if (size(deadIndices) > 0)
				% Delete the bodies from the array
				remainingBodies(deadIndices) = [];
			end

			% for all bodies
			for i = 1 : size(remainingBodies, 2)
				gravitationalBody = remainingBodies(i);

				if (~gravitationalBody.IsAlive)
					continue;
				end

				% Check for collisions
				for j = 1 : size(remainingBodies, 2)
					otherGravitationalBody = remainingBodies(j);

					% Skip itself
					if (j == i)
						continue;
					end

					if (~otherGravitationalBody.IsAlive)
						continue;
					end

					isColliding = gravitationalBody.IsCollidingWith(otherGravitationalBody);
					if (isColliding)
						if (otherGravitationalBody.IsFixedPoint)
							otherGravitationalBody.AbsorbBody(gravitationalBody);
						else
							if (gravitationalBody.CalculateMass() > otherGravitationalBody.CalculateMass())
								gravitationalBody.AbsorbBody(otherGravitationalBody);
							else
								otherGravitationalBody.AbsorbBody(gravitationalBody);
							end

						end
					else
						% Compute the forces
						gravitationalBody.ComputeForces(otherGravitationalBody);
					end
				end
			end

			% Simulate all forces
			for j = 1 : size(remainingBodies, 2)
				gravitationalBody = remainingBodies(j);

				if (~gravitationalBody.IsAlive)
					continue;
				end	

				gravitationalBody.SimulateForces(deltaTime, seconds);
			end

			% Finally, draw all bodies
			hold(graphAxes, 'off') % Clear the previous frame (swap the buffers, essentially)
			for i = 1 : size(remainingBodies, 2)
				gravitationalBody = remainingBodies(i);

				if (~gravitationalBody.IsAlive)
					continue;
				end

				gravitationalBody.Draw(graphAxes);

				if (i == 1)
					hold(graphAxes, 'on');
				end
			end


			drawnow;
			pause(0.01);

			%remainingBodies = gravitationalBodies;
			timeTaken = toc;
		end
	end
	
	methods
		function obj = GravitationalBody(initialXY, initialRadius, initialRGB, isFixedPoint)
			% GRAVITATIONALBODY Creates a new instance of the
			% GravitationalBody class.
			%	GRAVITATIONALBODY(this, initialXY, initialRadius, initialRGB, isFixedPoint)
			%	Creates a new instance of the GravitationalBody class using
			%	the supplied initial values, and whether or not the
			%	instance is a fixed point in the simulation.
			
			obj.XY = initialXY;
			obj.Radius = initialRadius;
			obj.RGB = initialRGB;
			obj.IsFixedPoint = isFixedPoint;
		end
		
		function isColliding = IsCollidingWith(this, gravitationalBody)
			% ISCOLLIDINGWITH Determines whether or not this body is 
			%	colliding with the provided body.
			%	ISCOLLIDINGWITH(gravitationalBody) Returns true if the
			%	bodies are colliding; otherwise, false.
			
			if (~isa(gravitationalBody, 'GravitationalBody'))
				fprintf('Invalid input object to ApplyForces - must be another gravitational body.');
				return;
			end
			
			collisionThreshold = this.Radius + gravitationalBody.Radius;
			
			if (this.DistanceTo(gravitationalBody) <= collisionThreshold)
				isColliding = true;
			else
				isColliding = false;
			end
		end
		
		function distance = DistanceTo(this, gravitationalBody)
			% DISTANCETO Computes the distance between this body and
			%	another supplied body.
			%	DISTANCETO(gravitationalBody) Computes the absolute
			%	distance to another body from this body, using the formula 
			%	derived from the pythagorean theorem.
			
			if (~isa(gravitationalBody, 'GravitationalBody'))
				fprintf('Invalid input object to ApplyForces - must be another gravitational body.');
				return;
			end
			
			distance = sqrt ( ...
				(gravitationalBody.XY(1) - this.XY(1))^2 ...
				+ ...
				(gravitationalBody.XY(2) - this.XY(2))^2 ...
				);
		end
		
		function mass = CalculateMass(this)
			% COMPUTEMASS Calculates the absolute mass of this body, using
			% the radius.
			%	mass = COMPUTEMASS() Calculates the mass of the body using
			%	the area function of a circle. In this 2D simulation, 
            %   the mass is represented by the area of the body, multiplied
            %   by the average density of a rocky body such as the Earth.
			
			mass = this.Radius^(2) * pi * 5.5;
		end
		
		% Github Issue #2
		function ComputeForces(this, gravitationalBody)
			% COMPUTEFORCES Computes the forces between the input body and
			% this body.
			%	COMPUTEFORCES(gravitationalBody) Computes the
			%	gravitational forces which the input body applies to this
			%	body, and cumulatively applies them to this body's stored
			%	forces.
			
			% Fixed points have no need to calculate forces on themselves
			if (this.IsFixedPoint)
				return;
			end
			
			if (~isa(gravitationalBody, 'GravitationalBody'))
				fprintf('Invalid input object to ApplyForces - must be another gravitational body.');
				return;
			end
			
			% Calculate the force the input body exerts on this body
			
			% Apply this force cumulatively onto the following variables:
			% this.Acceleration
			% this.XYDirection
            G = 6.67408e-11;
            
			distance = this.DistanceTo(gravitationalBody);
            force = G * ((this.CalculateMass() * gravitationalBody.CalculateMass()) / distance^2);
			forceVector = force * (this.XY - gravitationalBody.XY) / distance; 
			
			this.AccelerationVector = this.AccelerationVector - (forceVector / this.CalculateMass());
		end
		
		% Github Issue #3
		function SimulateForces(this, deltaTime, timeStep)
			% SIMULATEFORCES Simulate the calculated forces over a period of time
			%	SIMULATEFORCES(deltaTime, seconds) Applies the forces over a period of
			%	s seconds, adjusted by deltaTime.
			
			% Fixed points have no need to simulate forces on themselves
			if (this.IsFixedPoint)
				return;
			end
            
			if (~isnumeric(deltaTime))
				fprintf('Invalid input. "deltaTime" must be a numeric value strictly more than 0.');
			end
			
			if (~isnumeric(timeStep))
				fprintf('Invalid input. "Seconds" must be a numeric value strictly more than 0.');
			end
			
			if (timeStep <= 0)
				fprintf('Invalid input. "Seconds" must be strictly more than 0.');
			end
            	
			% Apply the calculated forces on the body 
			
			this.VelocityVector = this.VelocityVector + ((deltaTime * timeStep) * this.AccelerationVector);
			this.XY = this.XY + ((deltaTime * timeStep) * this.VelocityVector);
        end
        
		% GitHub Issue #1
		function AbsorbBody(this, gravitationalBody)
			% ABSORBBODY Absorbs the input body, combining its mass with the
			% mass of this body.
			%	ABSORBBODY(seconds) Absorb the input body. The masses of the
			%	input body and this body are added, and their positions
			%	averaged between each other.
			
			% Combine the masses
			this.Radius = sqrt((gravitationalBody.Radius^2*pi + this.Radius^2*pi) / pi);
			
			% Fixed points have no movement
			if (~this.IsFixedPoint)
				% Compute and apply the average resultant force
				forceBodyOne = this.AccelerationVector * this.CalculateMass();
				forceBodyTwo = gravitationalBody.AccelerationVector * gravitationalBody.CalculateMass();
				
				this.AccelerationVector = (forceBodyOne + forceBodyTwo) / this.CalculateMass();
				
				forceBodyOne = this.VelocityVector * this.CalculateMass();
				forceBodyTwo = gravitationalBody.VelocityVector * gravitationalBody.CalculateMass();
				
				this.VelocityVector = (forceBodyOne + forceBodyTwo) / this.CalculateMass();
			end
			
			
			% "Kill" the other body, removing it from the simulation
			gravitationalBody.Kill();
		end
		
		function Kill(this)
			% KILL Kills the body, removing it from the simulation.
			%	KILL(this) Kills this body, settings its alive flag to 
			%	false and
			%	deleting its graphical object.
			
			this.IsAlive = false;
			delete(this.GraphicalObject);
		end
		
		function Draw(this, graphAxes)
			% DRAW Draws the body in the provided axes.
			%	DRAW(this, graphAxes) Draws a circular representation of this body 
			%	in the provided axes.
			
			xpos = this.XY(1) - this.Radius;
			ypos = this.XY(2) - this.Radius;
			side = this.Radius * 2;
			
			delete(this.GraphicalObject);
			
			this.GraphicalObject = rectangle(...
					'Position', [xpos, ypos, side, side], ...
					'Curvature', [1, 1], ...
					'FaceColor', this.RGB);
		end
	end
end