function fcn_viz_draw_circles(centers, radii, colors, fig)

figure(fig);
% Step 3: Loop to draw each circle
for i = 1:size(centers, 1)
    % Draw a filled circle using rectangle
    rectangle('Position', [centers(i, 1) - radii(i), centers(i, 2) - radii(i), 2 * radii(i), 2 * radii(i)], ...
              'Curvature', [1, 1], ...     % This makes it a circle
              'FaceColor', colors(i, :), ... % Fill color
              'EdgeColor', 'none');          % No edge color
    hold on;
end

end