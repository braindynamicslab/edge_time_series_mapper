function varargout = fcn_mapper_drawd3graph(nodemat, nodecomm, cmap, outputname, prop, varargin)
    
    p = inputParser;
    addParameter(p, 'XY', []);
    addParameter(p, 'labels', []);
    addParameter(p, "minimal_radius", 0.1);
    addParameter(p, "radius_scaling_factor", 2);
    addParameter(p, "colorbar_flag", 1);

    parse(p, varargin{:});
    XY = p.Results.XY;
    labels = p.Results.labels;
    minimal_radius = p.Results.minimal_radius;
    radius_scaling_factor = p.Results.radius_scaling_factor;
    colorbar_flag = p.Results.colorbar_flag;

    if isempty(XY)
        fig = figure;
        set(gcf,'Visible','off');
        h=plot(graph(nodemat),'Layout', 'force','UseGravity','on','MarkerSize',2,'nodeCdata',nodecomm); colormap(cmap)
        XY = 2*[h.XData' h.YData'];
        close(fig);
    end
    
    [e_i,e_j,e_v] = find(nodemat);
    e_ii = e_i(e_i < e_j);
    e_jj = e_j(e_i < e_j);
    % num_nodes = size(nodemat, 1);
    % edge_lengths = zeros(num_nodes, 1);
    % parfor e = 1:length(e_i)
    %     edge_lengths(e) = norm(XY(e_i(e), :) - XY(e_j(e), :));
    % end
    % figure; histogram(edge_lengths);
    % unscaled_radii = sum(prop,2)./sum(sum(prop,2));
    % figure; histogram(unscaled_radii);
    


    fig = figure; set(gcf,'Position',[1000         612         884         725]);
    set(fig, 'ToolBar', 'none');
    set(fig, 'MenuBar', 'none');
    %[~, ~, prop] = createJSON_NodePie_cme(nodetpmat, nodemat, metaInfo, '', 1, 0);
    percents = prop./sum(prop,2);
    radius = minimal_radius + radius_scaling_factor*sqrt(sum(prop,2)./sum(sum(prop,2)));

    % draw edges
    plot([XY(e_ii, 1)'; XY(e_jj, 1)'], [XY(e_ii, 2)'; XY(e_jj, 2)'], 'Color', [0.6,0.6,0.6,0.3]);
    hold on;
    % for e = 1:1:length(e_i)
    %    plot([XY(e_i(e),1), XY(e_j(e),1)],[XY(e_i(e),2), XY(e_j(e),2)],'Color',[0.6,0.6,0.6,0.3]); 
    %    hold on;
    % end

    % draw piecharts
    colors = cmap;
    for n = 1:1:length(nodecomm)
        hold on;
        pos = XY(n,:);
        fcn_mapper_drawpie(percents(n,:),pos,radius(n),colors)
    end
    alpha(0.9);
    hold on;
    
    if colorbar_flag && ~isempty(labels)
        colormap(cmap);
        c=colorbar;
        c.Ticks=((1:1:length(labels)) - 0.5) / length(labels);
        c.TickLabels=labels;
    end



    set(fig,'Color','White')
    box off
    axis off
    %bringing patches above lines
    % ax = gca;
    % ax.Children;
    % ax.Children = ax.Children(end:-1:1);
    %export_fig([outputname,'.png'],'-transparent','-m3');
    
    %plot2svg([outputname '.svg']);

    exportgraphics(fig,strcat(outputname,'.pdf'),'ContentType','vector');
    close all;

    if nargout > 0
        varargout{1} = XY;
    end

    
end