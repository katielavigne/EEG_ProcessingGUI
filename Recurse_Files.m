function Recurse_Files(args, func_name )
%RECURSE_FILES Summary of this function goes here
%   Detailed explanation goes here

directory = args{1};
files = dir(directory);
sub_dir = dir(directory);
for i=size(sub_dir):-1:1
	if(~sub_dir(i).isdir) 
		sub_dir(i) = [];
	end
end
for i=size(files):-1:1
	if(files(i).isdir) 
		files(i) = [];
	end
end
if~isempty(files)
        evaluation = [func_name '(args, files)'];
        eval(evaluation);
end

for j = 1:size(sub_dir)
	if ~(isequal(sub_dir(j).name, '.') || isequal(sub_dir(j).name, '..'))
        args{1} = [directory filesep sub_dir(j).name];
		Recurse_Files(args, func_name);
	end
end
end


