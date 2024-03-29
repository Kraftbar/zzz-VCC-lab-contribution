

%% 1 read the network data and set the IDs of the cars
% TODO:
% Now the logfile is produced munualy because the origianl the colomuns
% is not lining up. This can be solved be adding a caracter infront of
% the logfile of Omnet

%   EKS fromat

M = dlmread('del_chosen_100s.dat');
something=[M(:,1);M(:,2)];
something=sort(unique(something));
len=length(sort(unique(something)));
for i=1:len
    for row=1:size(M,1)
        for col=1:size(M,2)
            if(M(row,col)==something(i))
                M(row,col)=i;
            end
        end
    end
end


%% 2 Read the xml - netconvert and the outputfile

a=xml2struct('G6_badaling_fcd_output[674].xml')
route=xml2struct('testmap.net.xml');






%% 3 Find car route and ID log
done=0;
RouteCar1=[];
laneIDs=[string(a.fcd_dash_export.timestep{1}.vehicle.Attributes.lane)];
tester=0;
for j =1:length(a.fcd_dash_export.timestep) % timestep
    for i = 1:numel(a.fcd_dash_export.timestep{j}.vehicle) % cars
        if(length(a.fcd_dash_export.timestep{j}.vehicle)==1)
            data=a.fcd_dash_export.timestep{j}.vehicle.Attributes;
            
        else
            data=a.fcd_dash_export.timestep{j}.vehicle{i}.Attributes;
        end
        laneID=(data.lane);
        
        % Gets info first car
        % gethers it to RouteCar1
        if(data.id=="1.0")
            dataAng=str2num(data.angle);
            dataX=str2num(data.x);
            dataY=str2num(data.y);
            if( ~(strcmp(string(data.lane),laneIDs(end)) ))
                laneIDs=[laneIDs   string(data.lane)];
            end
            RouteCar1=[RouteCar1; dataX dataY dataAng];
        end
        
        tester=tester+1;
    end
    if (tester==300)
        break;
    end
end

bias=(min(RouteCar1));
RouteCar1=[RouteCar1(:,1)-bias(1),RouteCar1(:,2)-bias(2),RouteCar1(:,3)];
RouteCar1=[RouteCar1(:,1)/10,RouteCar1(:,2)/10,RouteCar1(:,3)];
% a.fcd_dash_export.timestep{1, 20}.vehicle{2}.Attributes.angle
% a.fcd_dash_export.timestep{1, 2}.vehicle.Attributes.angle






%% 4 FIND edges based on the route
road=[];
d=0
Cordinates=[zeros(length(laneIDs),6)]
Cordinates2d=[]

realRoad=[]
found=0
for i= 1:length(laneIDs)
    for j =1:length(route.net.edge) % timestep
        if(length(route.net.edge{j}.lane)>1)
            for k=1:length(route.net.edge{j})
                if(strcmp(route.net.edge{j}.lane{k}.Attributes.id,laneIDs(i)))
                    
                    % FOUND MATCHING
                    found=1;
                    cords=str2num(route.net.edge{j}.lane{k}.Attributes.shape);
                    for n=1:length(cords)
                        Cordinates(i,n)=cords(n);
                        
                        if(~mod(n,2))
                            Cordinates2d=[Cordinates2d; cords(n-1),cords(n)]
                        end
                        
                    end
                    d=d+1;
                end
            end
        else
            if(strcmp(route.net.edge{j}.lane.Attributes.id,laneIDs(i)))
                % found matching
                found=1
                
                
                cords=str2num(route.net.edge{j}.lane.Attributes.shape);
                for n=1:length(cords)
                    Cordinates(i,n)=cords(n);
                    
                    if(~mod(n,2))
                        Cordinates2d=[Cordinates2d; cords(n-1),cords(n)]
                    end
                    
                end
                d=d+1
            end
        end
        if(found && length(fieldnames(route.net.edge{j}.Attributes))>5)
            cords=str2num(route.net.edge{j}.Attributes.shape);
            for n=1:length(cords)
                if(~mod(n,2))
                    realRoad=[realRoad; cords(n-1),cords(n)]
                end
            end
        end
        found=0;
    end
end


%% 5 Write the road to file


road=[]
for i=1:length(RouteCar1(:,1))
    road =[road RouteCar1(i,1) 0.01 RouteCar1(i,2)+10];
    road =[road RouteCar1(i,1) 0.01 RouteCar1(i,2)-10];
end


fileID = fopen('pointsSumo.txt','w');
fprintf(fileID,"[");
fprintf(fileID,'%6.2f %6.2f %6.2f, \n ',(road));
fprintf(fileID,']');
fclose(fileID);





% -0.9210
drawOrder=[]
for i=0:length(RouteCar1(:,1))-3 % riktig
    i=i*2;
    drawOrder=[drawOrder 0+i 2+i 3+i 1+i -1];
end

fileID = fopen('draw.txt','w');
fprintf(fileID,"[");
fprintf(fileID,'%i ,',drawOrder);
fprintf(fileID,"]");
fclose(fileID);
