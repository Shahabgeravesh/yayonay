import React, { useState, useEffect } from 'react';
import {
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Paper,
    Button,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    IconButton,
    Snackbar,
    Alert,
    CircularProgress
} from '@mui/material';
import { Edit, Delete, Add, Restore } from '@mui/icons-material';
import automatedCRUD from '../automated-crud';

const AutomatedCRUDTable = ({
    collection,
    requiredFields = [],
    columns,
    defaultSort = { field: 'createdAt', direction: 'desc' },
    pageSize = 10
}) => {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [openDialog, setOpenDialog] = useState(false);
    const [selectedItem, setSelectedItem] = useState(null);
    const [formData, setFormData] = useState({});
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });

    // Load data
    const loadData = async () => {
        try {
            setLoading(true);
            const queryParams = {
                orderBy: defaultSort,
                limit: pageSize
            };
            const result = await automatedCRUD.readDocuments(collection, queryParams);
            setData(result);
        } catch (err) {
            setError(err.message);
            showSnackbar(err.message, 'error');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, [collection]);

    // Show snackbar message
    const showSnackbar = (message, severity = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    // Handle dialog open/close
    const handleOpenDialog = (item = null) => {
        setSelectedItem(item);
        setFormData(item || {});
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setSelectedItem(null);
        setFormData({});
        setOpenDialog(false);
    };

    // Handle form input changes
    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    // Handle CRUD operations
    const handleCreate = async () => {
        try {
            setLoading(true);
            await automatedCRUD.createDocument(collection, formData, requiredFields);
            showSnackbar('Item created successfully');
            handleCloseDialog();
            loadData();
        } catch (err) {
            showSnackbar(err.message, 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleUpdate = async () => {
        try {
            setLoading(true);
            await automatedCRUD.updateDocument(collection, selectedItem.id, formData, requiredFields);
            showSnackbar('Item updated successfully');
            handleCloseDialog();
            loadData();
        } catch (err) {
            showSnackbar(err.message, 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id) => {
        try {
            setLoading(true);
            await automatedCRUD.deleteDocument(collection, id);
            showSnackbar('Item deleted successfully');
            loadData();
        } catch (err) {
            showSnackbar(err.message, 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleRestore = async (id) => {
        try {
            setLoading(true);
            await automatedCRUD.restoreDocument(collection, id);
            showSnackbar('Item restored successfully');
            loadData();
        } catch (err) {
            showSnackbar(err.message, 'error');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div>
            <Button
                variant="contained"
                color="primary"
                startIcon={<Add />}
                onClick={() => handleOpenDialog()}
                style={{ marginBottom: 20 }}
            >
                Add New
            </Button>

            <TableContainer component={Paper}>
                <Table>
                    <TableHead>
                        <TableRow>
                            {columns.map(column => (
                                <TableCell key={column.field}>{column.header}</TableCell>
                            ))}
                            <TableCell>Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={columns.length + 1} align="center">
                                    <CircularProgress />
                                </TableCell>
                            </TableRow>
                        ) : (
                            data.map(item => (
                                <TableRow key={item.id}>
                                    {columns.map(column => (
                                        <TableCell key={`${item.id}-${column.field}`}>
                                            {item[column.field]}
                                        </TableCell>
                                    ))}
                                    <TableCell>
                                        <IconButton
                                            color="primary"
                                            onClick={() => handleOpenDialog(item)}
                                        >
                                            <Edit />
                                        </IconButton>
                                        <IconButton
                                            color="error"
                                            onClick={() => handleDelete(item.id)}
                                        >
                                            <Delete />
                                        </IconButton>
                                        <IconButton
                                            color="success"
                                            onClick={() => handleRestore(item.id)}
                                        >
                                            <Restore />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog open={openDialog} onClose={handleCloseDialog}>
                <DialogTitle>
                    {selectedItem ? 'Edit Item' : 'Create New Item'}
                </DialogTitle>
                <DialogContent>
                    {columns.map(column => (
                        <TextField
                            key={column.field}
                            name={column.field}
                            label={column.header}
                            value={formData[column.field] || ''}
                            onChange={handleInputChange}
                            fullWidth
                            margin="normal"
                            required={requiredFields.includes(column.field)}
                        />
                    ))}
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleCloseDialog}>Cancel</Button>
                    <Button
                        onClick={selectedItem ? handleUpdate : handleCreate}
                        color="primary"
                        disabled={loading}
                    >
                        {loading ? <CircularProgress size={24} /> : (selectedItem ? 'Update' : 'Create')}
                    </Button>
                </DialogActions>
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={6000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
            >
                <Alert
                    onClose={() => setSnackbar({ ...snackbar, open: false })}
                    severity={snackbar.severity}
                >
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </div>
    );
};

export default AutomatedCRUDTable; 