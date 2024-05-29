classdef NormDist
    
   properties
      mean
      sd      
   end
   
   methods(Static = true)
       function nds = init(means, sds)
          if length(means) == length(sds) && length(means) >= 1
             a = NormDist(0, 0);
             nds(length(means)) = a;
             for i = 1:length(means)
                nds(i).mean = means(i);
                nds(i).sd = sds(i);
             end
          else
              error('means and sds must be the same length and not empty.');
          end
       end
       
       function cs = averageCells(ndCells)
          %Requires each cell in ndCells to be a NormDist array of the same
          %size. Returns the elementwise average across the cells.
          if ~iscell(ndCells)
              error('Must be a cell array')
          end
          
          size1 = size(ndCells{1});
          ok = true;
          for i = 2:length(ndCells)
              if ~isa(ndCells{i}, 'NormDist')
                  error('each cell must contain an array of NormDists.');
              end

              sizen = size(ndCells{i}); 
              if length(sizen) ~= length(size1)
                  ok = false;
                  break;
              end
              if ~all(sizen == size1)
                  ok = false;
                  break;
              end      
          end
          
          if (~ok)
              error('All the arrays in the cell array must be the same size.');
          end
          
          % We're good.       
          len = prod(size1);
          cs = NormDist.init(zeros(len, 1), zeros(len, 1));
          as = NormDist.init(zeros(length(ndCells), 1), zeros(length(ndCells), 1));
          for i = 1:length(cs)
             for j = 1:length(ndCells)
                 as(j) = ndCells{j}(i);
             end
             cs(i) = average(as);
          end
          cs = reshape(cs, size1);
       end
       
       function cs = sumCells(ndCells)
          %Requires each cell in ndCells to be a NormDist array of the same
          %size. Returns the elementwise average across the cells.
          if ~iscell(ndCells)
              error('Must be a cell array')
          end
          
          size1 = size(ndCells{1});
          ok = true;
          for i = 2:length(ndCells)
              if ~isa(ndCells{i}, 'NormDist')
                  error('each cell must contain an array of NormDists.');
              end

              sizen = size(ndCells{i}); 
              if length(sizen) ~= length(size1)
                  ok = false;
                  break;
              end
              if ~all(sizen == size1)
                  ok = false;
                  break;
              end      
          end
          
          if (~ok)
              error('All the arrays in the cell array must be the same size.');
          end
          
          % We're good.       
          len = prod(size1);
          cs = NormDist.init(zeros(len, 1), zeros(len, 1));
          as = NormDist.init(zeros(length(ndCells), 1), zeros(length(ndCells), 1));
          for i = 1:length(cs)
             for j = 1:length(ndCells)
                 as(j) = ndCells{j}(i);
             end
             cs(i) = sum(as);
          end
          cs = reshape(cs, size1);
       end
       
   end
   
   methods
       
       function obj = NormDist(mean, sd)           
           if (nargin < 2)
               if (nargin == 1)
                   if (isfield(mean, 'mean') && isfield(mean, 'sd'))
                      % Weird case that was cropping up. Thanks Matlab.
                      obj.mean = mean.mean;
                      obj.sd = mean.sd;
                      return;
                   else
                      error('Can''t supply just one argument to NormDist constructor unless it''s a NormDist to copy.');
                   end
               end
               mean = 0;
               sd = 0;
           end
          if isnumeric(mean) && isnumeric(sd)
              obj.mean = mean;
              obj.sd = sd;
          else
              error('Can only create NormDist with numeric input.')
          end
       end
       
       function c = plus(a, b)
           if ~all(size(a) == size(b))
               error('arrays must be the same size.');
           end
           aMean = [a.mean];
           bMean = [b.mean];
           aSD = [a.sd];
           bSD = [b.sd];
           cMean = aMean + bMean;
           cSD = sqrt(aSD.^2 + bSD.^2);
           c = NormDist.init(cMean, cSD);
       end
       
       function c = minus(a, b)           
           if ~all(size(a) == size(b))
               error('arrays must be the same size.');
           end
           aMean = [a.mean];
           bMean = [b.mean];
           aSD = [a.sd];
           bSD = [b.sd];
           cMean = aMean - bMean;
           cSD = sqrt(aSD.^2 + bSD.^2);
           c = NormDist.init(cMean, cSD);
       end
       
       function c = times(a, b)
           if isa(a, 'NormDist') && isa(b, 'NormDist')
               if ((a.mean / a.sd) < 5 || (b.mean / b.sd) < 5)
                   % Basically, if we need the distribution to be far
                   % away from zero for this to work. Otherwise we
                   % can't really approximate the convolution as a
                   % normal distribution.
                   warning('Convolving Normal distributions with significant density close to zero. Approximation to normal distribution will be poor.');
               end                   
               c.mean = a.mean * b.mean;
               v = a.sd^2 * b.sd^2 + a.sd^2 * b.mean^2 + b.sd^2 * a.mean^2;
               c.sd = sqrt(v);
           elseif isa(a, 'NormDist')
               cms = [a.mean] .* b;
               csds = [a.sd] .* sqrt(abs(b));
               c = NormDist.init(cms, csds);
%               c.mean = a.mean .* b;
%               c.sd = a.sd .* sqrt(b);
           else
               cms = [b.mean] .* a;
               csds = [b.sd] .* sqrt(abs(a));
               c = NormDist.init(cms, csds);
              
%               c.mean = b.mean .* a;
%               c.sd = b.sd .* sqrt(a);
           end
       end
      
       function c = mtimes(a, b)
           if isa(a, 'NormDist') && isa(b, 'NormDist')               
               if length(a) == 1 && length(b) == 1
                   if ((a.mean / a.sd) < 5 || (b.mean / b.sd) < 5)
                       % Basically, if we need the distribution to be far
                       % away from zero for this to work. Otherwise we
                       % can't really approximate the convolution as a
                       % normal distribution.
                       warning('Convolving Normal distributions with significant density close to zero. Approximation to normal distribution will be poor.');
                   end
                   
                   c.mean = a.mean * b.mean;
                   v = a.sd^2 * b.sd^2 + a.sd^2 * b.mean^2 + b.sd^2 * a.mean^2;
                   c.sd = sqrt(v);
               else
                   error('mtimes only works on scalar NormDists');
               end
           elseif isa(a, 'NormDist')
               if length(b) == 1
                   if length(a) == 1
                       c.mean = a.mean * b;
                       c.sd = a.sd * sqrt(abs(b));                       
                   else
                       cmeans = [a.mean] * b;
                       csds = [a.sd] * sqrt(abs(b));
                       c = NormDist.init(cmeans, csds);
%                       c.mean = a.mean * b;
%                       c.sd = a.sd * sqrt(b);                                              
                   end
               else
                   error('mtimes only works on scalar NormDists');
               end
           else
               if (length(a) == 1)
                   if length(b) == 1
                       c.mean = b.mean * a;
                       c.sd = b.sd * sqrt(abs(a));
                   else
                       cmeans = [b.mean] * a;
                       csds = [b.sd] * sqrt(abs(a));
                       c = NormDist.init(cmeans, csds);
                   end
               else
                   error('mtimes only works on scalar NormDists');                   
               end
           end
       end
       
       function c = rdivide(a, b)
           if isa(a, 'NormDist') && isnumeric(b)
               c.mean = a.mean / b;
               c.sd = a.sd / sqrt(abs(b));
           else
               error('right side must be numeric')
           end
       end
       
       function c = average(as)           
           c = sum(as);
           c.mean = c.mean / length(as);
           c.sd = c.sd / sqrt(length(as));
           % It's divided by the sqrt of the cells because if we had used
           % the full equation rather than the sum, we'd have divided by
           % the number of items inside the sqaure root. Since we didn't
           % we'll 'put it back in' here by sqrting it.
       end
       
       function c = sum(as)
           c.mean = sum([as.mean]);
           c.sd = sqrt(sum([as.sd].*[as.sd]));
       end
       
   end
   
end