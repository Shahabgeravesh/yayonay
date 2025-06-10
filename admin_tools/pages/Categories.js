import React from 'react';
import { Container, Typography, Box } from '@mui/material';
import AutomatedCRUDTable from '../components/AutomatedCRUDTable';

const Categories = () => {
    const columns = [
        { field: 'name', header: 'Category Name' },
        { field: 'description', header: 'Description' },
        { field: 'imageUrl', header: 'Image URL' },
        { field: 'createdAt', header: 'Created At' }
    ];

    const requiredFields = ['name'];

    return (
        <Container maxWidth="lg">
            <Box py={4}>
                <Typography variant="h4" component="h1" gutterBottom>
                    Category Management
                </Typography>
                <Typography variant="body1" color="textSecondary" paragraph>
                    Create, edit, and manage categories for YayoNay questions.
                </Typography>

                <AutomatedCRUDTable
                    collection="categories"
                    columns={columns}
                    requiredFields={requiredFields}
                    pageSize={10}
                    defaultSort={{ field: 'createdAt', direction: 'desc' }}
                />
            </Box>
        </Container>
    );
};

export default Categories; 